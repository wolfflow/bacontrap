Bacontrap = require '../src/bacontrap.coffee'
window.Bacontrap = Bacontrap
{expect} = require 'chai'
sinon = require 'sinon'

simulateKeyEvent = (type, keyCode, bubbles=true, cancelable=true) ->
  event = document.createEvent('Event')
  event.initEvent(type, bubbles, cancelable)
  event.keyCode = event.which = keyCode
  event


describe "Bacontrap", ->
  describe '.match', ->
    it 'matches to characters', ->
      keyCode = 'A'.charCodeAt(0)
      expect(Bacontrap.match('a', which: keyCode)).to.be.ok

    it 'does not match to unexpected characters', ->
      keyCode = 'B'.charCodeAt(0)
      expect(Bacontrap.match('a', which: keyCode)).to.not.be.ok

    it 'matches to special keys', ->
      expect(Bacontrap.match('backspace', which: 8)).to.be.ok

    it 'matches with modifier keys', ->
      event = {which: 'A'.charCodeAt(0), shiftKey: true}
      expect(Bacontrap.match('shift+a', event)).to.be.ok

    it 'supports aliases', ->
      event = {which: 91} # meta
      expect(Bacontrap.match('command', event)).to.be.ok

    it 'supports as modifiers', ->
      event = {which: 'A'.charCodeAt(0), metaKey: true}
      expect(Bacontrap.match('command+a', event)).to.be.ok

    it 'supports aliases with multiple matches', ->
      event = {which: '0'.charCodeAt(0)}
      expect(Bacontrap.match('num', event)).to.be.ok

  describe '.trap', ->
    before ->
      @bus = new Bacon.Bus()

    it 'binds to keyboard shortcut', ->
      spy = sinon.spy()
      Bacontrap.trap(@bus, ['ctrl+num']).take(1).onValue spy

      event = {which: '0'.charCodeAt(0), ctrlKey: true}
      @bus.push event
      expect(spy.calledWith(event)).to.be.ok

    it 'handles sequences', ->
      spy = sinon.spy()
      Bacontrap.trap(@bus, ['l', 'o', 'l']).take(1).onValue spy

      @bus.push {which: 'l'.charCodeAt(0)}
      @bus.push {which: 'o'.charCodeAt(0)}
      @bus.push {which: 'l'.charCodeAt(0)}
      expect(spy.called).to.be.ok

    it 'breaks sequence when non-sequence key is pressed', ->
      spy = sinon.spy()
      Bacontrap.trap(@bus, ['l', 'o', 'l']).take(1).onValue spy

      @bus.push {which: 'l'.charCodeAt(0)}
      @bus.push {which: 'o'.charCodeAt(0)}
      @bus.push {which: 'r'.charCodeAt(0)}
      @bus.push {which: 'l'.charCodeAt(0)}
      expect(spy.called).to.not.be.ok

    it 'breaks sequence after idle time', ->
      clock = sinon.useFakeTimers()
      spy = sinon.spy()
      Bacontrap.trap(@bus, ['l', 'o', 'l']).take(1).onValue spy

      @bus.push {which: 'l'.charCodeAt(0)}
      @bus.push {which: 'o'.charCodeAt(0)}
      clock.tick(Bacontrap.defaults.timeout + 1)
      @bus.push {which: 'l'.charCodeAt(0)}
      clock.restore()
      expect(sinon.called).to.not.be.ok

  describe '.bind', ->
    it 'binds to keyboard shortcuts', ->
      spy = sinon.spy()
      Bacontrap.bind('l', 1).take(1).onValue spy
      event = simulateKeyEvent('keypress', 'l'.charCodeAt(0))
      document.dispatchEvent(event)
      expect(spy.calledWith(event)).to.be.ok

    it 'binds to array of shortcuts', ->
      spy = sinon.spy()
      Bacontrap.bind(['l', 'o']).take(2).onValue spy
      document.dispatchEvent(simulateKeyEvent('keypress', 'l'.charCodeAt(0)))
      document.dispatchEvent(simulateKeyEvent('keypress', 'o'.charCodeAt(0)))
      expect(spy.callCount).to.equal 2

    it 'can handle shortcuts with esc', ->
      spy = sinon.spy()
      Bacontrap.bind('esc a').take(1).onValue spy
      document.dispatchEvent(simulateKeyEvent('keydown', 27)) #esc
      document.dispatchEvent(simulateKeyEvent('keypress', 'a'.charCodeAt(0)))
      expect(spy.called).to.be.ok

    describe 'input fields', ->
      input = document.createElement('input')
      event = simulateKeyEvent('keypress', 'a'.charCodeAt(0))
      
      it 'ignores events from inputs by default', ->
        spy = sinon.spy()
        Bacontrap.bind('a').take(1).onValue spy
        # emulates $.Event target
        input.dispatchEvent(event)
        expect(spy.called).to.not.be.ok

      it 'can set global keyboard shortcuts', ->
        spy = sinon.spy()
        Bacontrap.bind('a', global: true).take(1).onValue spy
        # emulates $.Event target bubbling
        input.dispatchEvent(event)
        document.dispatchEvent(event)
        expect(spy.called).to.be.ok
