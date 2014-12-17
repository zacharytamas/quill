describe('Formatter', ->
  beforeEach( ->
    resetContainer()
    @container = $('#test-container').html('').get(0)
  )

  formats =
    attribute: new Quill.Formatter.Format(
      attribute: 'data-format'
    )
    class: new Quill.Formatter.Format(
      class: 'author-'
    )
    line: new Quill.Formatter.Format(
      style:
        textAlign: 'left'
    , Quill.Formatter.types.LINE)
    style: new Quill.Formatter.Format(
      style:
        color: 'red'
    )
    tag: new Quill.Formatter.Format(
      tag: 'B'
    )

  tests =
    tag:
      format: formats.tag
      existing: '<b>Text</b>'
      missing: 'Text'
      value: true
    style:
      format: formats.style
      existing: '<span style="color: blue;">Text</span>'
      missing: 'Text'
      value: 'blue'
    attribute:
      format: formats.attribute
      existing: '<span data-format="attribute">Text</a>'
      missing: 'Text'
      value: 'attribute'
    class:
      format: formats.class
      existing: '<span class="author-jason">Text</span>'
      missing: 'Text'
      value: 'jason'
    line:
      format: formats.line
      existing: '<div style="text-align: right;">Text</div>'
      missing: '<div>Text</div>'
      value: 'right'

  describe('value()', ->
    _.each(tests, (test, name) ->
      it("#{name} existing", ->
        @container.innerHTML = test.existing
        expect(test.format.value(@container.firstChild)).toEqual(test.value)
      )

      it("#{name} missing", ->
        @container.innerHTML = test.missing
        expect(test.format.value(@container.firstChild)).toBe(undefined)
      )
    )

    it('default', ->
      @container.innerHTML = '<span style="color: red;">Text</span>'
      expect(formats.style.value(@container.firstChild)).toBe(undefined)
    )
  )

  describe('add()', ->
    _.each(tests, (test, name) ->
      it("#{name} add value", ->
        @container.innerHTML = test.missing
        test.format.add(@container.firstChild, test.value)
        expect(@container).toEqualHTML(test.added or test.existing)
      )

      it("#{name} add value to exisitng", ->
        @container.innerHTML = test.existing
        test.format.add(@container.firstChild, test.value)
        expect(@container).toEqualHTML(test.existing)
      )
    )

    it('change value', ->
      @container.innerHTML = '<span style="color: blue;">Text</span>'
      formats.style.add(@container.firstChild, 'green')
      expect(@container).toEqualHTML('<span style="color: green;">Text</span>')
    )

    it('default value', ->
      @container.innerHTML = '<span>Text</span>'
      formats.style.add(@container.firstChild, 'red')
      expect(@container).toEqualHTML('<span>Text</span>')
    )

    it('class over existing', ->
      @container.innerHTML = '<span class="author-balto">Text</span>'
      formats.class.add(@container.firstChild, 'jason')
      expect(@container).toEqualHTML('<span class="author-jason">Text</span>')
    )
  )

  describe('remove()', ->
    _.each(tests, (test, name) ->
      it("#{name} existing", ->
        @container.innerHTML = test.existing
        test.format.remove(@container.firstChild)
        expect(@container).toEqualHTML(test.removed or test.missing)
      )

      it("#{name} missing", ->
        @container.innerHTML = test.missing
        test.format.remove(@container.firstChild)
        expect(@container).toEqualHTML(test.missing)
      )
    )
  )
)
