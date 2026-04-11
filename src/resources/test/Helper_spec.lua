-- Helper_spec.lua
--
-- Busted specs for the Helper module. Runs inside a headless Mudlet instance
-- via `npm test` (gesslardev/mudlet-busted Docker image), which loads every
-- entry in src/scripts/scripts.json before discovering specs. That means
-- `helper`, `Helper`, and Mudlet stdlib functions (`cecho`, `table.deepcopy`,
-- `table.update`) are already globals by the time these tests run.
--
-- Observability trick: `helper.print` side-effects into `cecho` and returns
-- nothing, so we replace `cecho` with a capturing stub in before_each. Each
-- test can then assert on the last string that would have been printed. The
-- real `cecho` is stashed in setup and restored in teardown so we don't leak
-- the stub out of this describe block.

describe("Helper module", function()
  local captured
  local original_cecho

  setup(function()
    original_cecho = _G.cecho
  end)

  teardown(function()
    _G.cecho = original_cecho
  end)

  before_each(function()
    captured = nil
    _G.cecho = function(s)
      captured = s
      return s
    end
  end)

  -------------------------------------------------------------------------
  -- print: basic parameter handling
  -------------------------------------------------------------------------

  describe("print", function()
    it("emits plain text unchanged with a trailing newline", function()
      helper.print({text = "hello"})
      assert.are.equal("hello\n", captured)
    end)

    it("handles empty text", function()
      helper.print({text = ""})
      assert.are.equal("\n", captured)
    end)

    it("defaults text to empty string when omitted", function()
      helper.print({})
      assert.are.equal("\n", captured)
    end)

    it("errors on a non-table parameter", function()
      assert.has_error(function()
        helper.print("not a table")
      end)
    end)

    it("errors when called with no argument at all", function()
      assert.has_error(function()
        helper.print()
      end)
    end)
  end)

  -------------------------------------------------------------------------
  -- default styles (h1..h6)
  -------------------------------------------------------------------------

  describe("default styles", function()
    it("resolves <h1> to <red>", function()
      helper.print({text = "<h1>hi"})
      assert.are.equal("<red>hi\n", captured)
    end)

    it("resolves <h2>..<h6> to their default colours", function()
      helper.print({text = "<h2>a<h3>b<h4>c<h5>d<h6>e"})
      assert.are.equal("<blue>a<yellow>b<green>c<magenta>d<cyan>e\n", captured)
    end)

    it("is case-insensitive on tag names", function()
      helper.print({text = "<H1>hi"})
      assert.are.equal("<red>hi\n", captured)
    end)
  end)

  -------------------------------------------------------------------------
  -- closing tags (documented: always emit <reset>, no nesting)
  -------------------------------------------------------------------------

  describe("closing tags", function()
    it("rewrites any </x> to <reset>", function()
      helper.print({text = "<h1>hi</h1>"})
      assert.are.equal("<red>hi<reset>\n", captured)
    end)

    it("rewrites </unknown> to <reset> even for unknown tags", function()
      helper.print({text = "<unknown>x</unknown>"})
      assert.are.equal("<unknown>x<reset>\n", captured)
    end)
  end)

  -------------------------------------------------------------------------
  -- custom style merging
  -------------------------------------------------------------------------

  describe("custom styles", function()
    it("adds a new style that is not in defaults", function()
      helper.print({
        text = "<danger>warning",
        styles = {danger = "orange_red"},
      })
      assert.are.equal("<orange_red>warning\n", captured)
    end)

    it("overrides a default style", function()
      helper.print({
        text = "<h1>hi",
        styles = {h1 = "chartreuse"},
      })
      assert.are.equal("<chartreuse>hi\n", captured)
    end)

    it("keeps defaults for keys the caller did not override", function()
      helper.print({
        text = "<h1>a<h2>b",
        styles = {h1 = "chartreuse"},
      })
      assert.are.equal("<chartreuse>a<blue>b\n", captured)
    end)
  end)

  -------------------------------------------------------------------------
  -- unknown style tags
  -------------------------------------------------------------------------

  describe("unknown style tags", function()
    it("passes the tag through unchanged", function()
      helper.print({text = "<unknown>x"})
      assert.are.equal("<unknown>x\n", captured)
    end)
  end)

  -------------------------------------------------------------------------
  -- function tags
  -------------------------------------------------------------------------

  describe("function tags", function()
    after_each(function()
      _G.helperTestFn = nil
      _G.HelperTestNS = nil
    end)

    it("calls a plain global function with zero arguments", function()
      _G.helperTestFn = function(...)
        -- If the bug where ns was passed as nil ever comes back, this fails.
        assert.are.equal(0, select("#", ...))
        return "1.2.3"
      end
      helper.print({text = "<@helperTestFn>"})
      assert.are.equal("1.2.3\n", captured)
    end)

    it("calls a namespaced function with the namespace as self", function()
      _G.HelperTestNS = {
        _url = "https://example.com",
        url = function(self) return self._url end,
      }
      helper.print({text = "<@HelperTestNS:url>"})
      assert.are.equal("https://example.com\n", captured)
    end)

    it("recursively processes returned text as help tags", function()
      _G.helperTestFn = function() return "<h1>title" end
      helper.print({text = "<@helperTestFn>"})
      assert.are.equal("<red>title\n", captured)
    end)

    it("preserves caller styles when the function returns only text", function()
      -- Regression test: earlier version called processText(result_text)
      -- without forwarding caller styles, so custom styles silently dropped
      -- out of scope inside a function tag's output.
      _G.helperTestFn = function() return "<h1>title" end
      helper.print({
        text = "<@helperTestFn>",
        styles = {h1 = "chartreuse"},
      })
      assert.are.equal("<chartreuse>title\n", captured)
    end)

    it("layers function styles on top of caller styles", function()
      -- Caller provides h1, function adds h2. Both should apply.
      _G.helperTestFn = function()
        return "<h1>title<h2>sub", {h2 = "orange_red"}
      end
      helper.print({
        text = "<@helperTestFn>",
        styles = {h1 = "chartreuse"},
      })
      assert.are.equal("<chartreuse>title<orange_red>sub\n", captured)
    end)

    it("lets function styles override caller styles for the same key", function()
      _G.helperTestFn = function()
        return "<h1>won", {h1 = "gold"}
      end
      helper.print({
        text = "<@helperTestFn>",
        styles = {h1 = "silver"},
      })
      assert.are.equal("<gold>won\n", captured)
    end)

    it("emits <error executing X> when the function errors", function()
      _G.helperTestFn = function() error("kaboom") end
      helper.print({text = "<@helperTestFn>"})
      assert.are.equal("<error executing helperTestFn>\n", captured)
    end)

    it("emits <invalid function X> for a nonexistent function", function()
      helper.print({text = "<@nothingHere>"})
      assert.are.equal("<invalid function nothingHere>\n", captured)
    end)
  end)

  -------------------------------------------------------------------------
  -- instance mode (Helper() constructor + instance methods)
  -------------------------------------------------------------------------

  describe("instance mode", function()
    it("Helper() returns a fresh table instance", function()
      local inst = Helper()
      assert.is_not_nil(inst)
      assert.are.equal("table", type(inst))

      local inst2 = Helper()
      assert.are_not.equal(inst, inst2)
    end)

    it("instance:print renders the same output as module print", function()
      local inst = Helper()
      inst:print({text = "<h1>hello</h1>"})
      assert.are.equal("<red>hello<reset>\n", captured)
    end)

    it("tostring(instance) reports the module version", function()
      local inst = Helper()
      local s = tostring(inst)
      assert.is_not_nil(s:find("Helper Instance", 1, true))
      assert.is_not_nil(s:find(Helper._VERSION, 1, true))
    end)
  end)

  -------------------------------------------------------------------------
  -- module identity
  -------------------------------------------------------------------------

  describe("module identity", function()
    it("exposes helper and Helper as the same table", function()
      assert.are.equal(Helper, helper)
    end)

    it("exposes _VERSION, _DESCRIPTION and _URL", function()
      assert.is_not_nil(Helper._VERSION)
      assert.is_not_nil(Helper._DESCRIPTION)
      assert.is_not_nil(Helper._URL)
    end)
  end)
end)
