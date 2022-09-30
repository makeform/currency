module.exports =
  pkg:
    name: "@makeform/input", extend: {name: "@makeform/common"}
    dependencies: [{name: "marked", version: "main", path: "marked.min.js"}]
    i18n:
      "en": "單位": "unit"
      "zh-TW": "unit": "單位"
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)

mod = ({root, ctx, data, parent, t}) -> 
  {ldview,marked} = ctx
  lc = {}
  init: ->
    lc = @mod.child = {}
    lc.currency = @mod.info.config.default-currency or @mod.info.config.available-currencies.0
    view = {}
    @on \change, (v) ~>
      c = @content v
      if !(c?) => c = ''
      if view.get(\input).value == c => return
      view.get(\input).value = c
      view.render <[preview input content]>
    handler = ({node}) ~>
      v = @value!
      if @content(v) == (nv = node.value) and lc.currency == v.currency => return
      if v and typeof(v) == \object => v <<< {v: nv, currency: lc.currency}
      else v = {v: nv, currency: lc.currency}
      @value v
    lc.view = view = new ldview do
      root: root
      action:
        input: input: handler
        change:
          input: handler
          "enable-markdown-input": ({node}) ~>
            lc.markdown = node.checked
            if !lc.markdown => lc.preview = false
            if typeof(v = @value!) != \object => v = {v: v}
            v.markdown = lc.markdown
            @value v
            view.render!
        click:
          mode: ({node}) ->
            lc.preview = if node.getAttribute(\data-name) == \preview => true else false
            view.render!
      text:
        unit: ({node}) ~> t(@mod.info.config.unit or '')
        currency: ({node}) ~> t(lc.currency or '...')
      handler:
        dropdown: ({node}) -> new BSN.Dropdown node
        "available-currency":
          list: ~> @mod.info.config.available-currencies or <[TWD]>
          key: -> it
          view:
            text: "@": ({node, ctx}) -> t(ctx)
            action: click: "@": ({ctx, views})  ->
              lc.currency = ctx
              views.1.render \currency

        input: ({node}) ~>
          readonly = !!@mod.info.meta.readonly
          if readonly => node.setAttribute \readonly, true
          else node.removeAttribute \readonly
          node.classList.toggle \is-invalid, @status! == 2
          if @mod.info.config.placeholder => node.setAttribute \placeholder, @mod.info.config.placeholder
          else node.removeAttribute \placeholder
        content: ({node}) ~>
          val = @content!
          text = if @is-empty! => "n/a"
          else val + (if @mod.info.config.unit => that else "")
          node.classList.toggle \text-muted, @is-empty!
          node.innerText = text

  render: -> @mod.child.view.render!
  is-empty: (v) ->
    v = @content(v)
    return (typeof(v) == \undefined) or (typeof(v) == \string and v.trim! == "") or v == null
  content: (v) ->
    if v and typeof(v) == \object => v.v else v

