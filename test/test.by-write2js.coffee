fs = require('fs')
path = require('path')
async = require('async')
rimraf = require('rimraf')
mkdirp = require('mkdirp')
chai = require('chai')
Bystander = require('bystander')
should = chai.should()
coffee = require('coffee-script')
ByWrite2JS = require('../lib/by-write2js')

describe('ByWrite2JS', ->
  GOOD_CODE = 'foo = 1'
  BAD_CODE = 'foo ==== 1'
  TMP = "#{__dirname}/tmp"
  FOO = "#{TMP}/foo"
  FOO2 = "#{TMP}/foo2"
  NODIR = "#{TMP}/nodir"
  NOFILE = "#{TMP}/nofile.coffee"
  HOTCOFFEE = "#{TMP}/hot.coffee"
  BLACKCOFFEE = "#{TMP}/black.coffee"
  ICEDCOFFEE = "#{FOO}/iced.coffee"
  ICEDJS = "#{FOO}/iced.js"
  BIN = "#{FOO}/iced.bin.coffee"
  BINJS = "#{FOO}/iced"
  TMP_BASE = path.basename(TMP)
  FOO_BASE = path.basename(FOO)
  FOO2_BASE = path.basename(FOO2)
  NODIR_BASE = path.basename(NODIR)
  NOFILE_BASE = path.basename(NOFILE)
  HOTCOFFEE_BASE = path.basename(HOTCOFFEE)
  BLACKCOFFEE_BASE = path.basename(BLACKCOFFEE)
  ICEDCOFFEE_BASE = path.basename(ICEDCOFFEE)
  NO_COMPILE = ["**/foo/*"]
  MAPPER = {"**/foo/*" : [/\/foo\//,'/foo2/']}
  COMPILED = coffee.compile(GOOD_CODE)
  bystander = new Bystander()
  byWrite2JS = new ByWrite2JS()
  stats = {}

  beforeEach((done) ->
    mkdirp(FOO, (err) ->
      async.forEach(
        [HOTCOFFEE, ICEDCOFFEE],
        (v, callback) ->
          fs.writeFile(v, GOOD_CODE, (err) ->
            async.forEach(
              [FOO, HOTCOFFEE,ICEDCOFFEE,BLACKCOFFEE],
              (v, callback2) ->
                fs.stat(v, (err,stat) ->
                  stats[v] = stat
                  callback2()
                )
              ->
                callback()
            )
          )
        ->
          byWrite2JS = new ByWrite2JS({nolog:true, root: TMP})
          done()
      )
    )
  )

  afterEach((done) ->
    rimraf(TMP, (err) =>
      byWrite2JS.removeAllListeners()
      done()
    )
  )

  describe('constructor', ->
    it('init test', ->
      ByWrite2JS.should.be.a('function')
    )
    it('should instanciate', ->
      byWrite2JS.should.be.a('object')
    )
    it('should set @mapper', () ->
      byWrite2JS.mapper.should.be.empty
      byWrite2JS = new ByWrite2JS({mapper:MAPPER})
      byWrite2JS.mapper.should.eql(MAPPER)
    )
    it('should set @opts.bin', () ->
      byWrite2JS.opts.bin.should.not.be.ok
      byWrite2JS = new ByWrite2JS({bin:true})
      byWrite2JS.opts.bin.should.be.ok
    )
    it('should set @opts.binDir', () ->
      byWrite2JS.opts.binDir.should.equal("#{TMP}/bin")
      byWrite2JS = new ByWrite2JS({root:TMP, binDir:FOO})
      byWrite2JS.opts.binDir.should.equal(FOO)
    )

  )

  describe('_replaceExt', ->
    it('should replace file extension', () ->
      byWrite2JS._replaceExt(HOTCOFFEE).should.equal("#{TMP}/hot.js")
      byWrite2JS._replaceExt(HOTCOFFEE, 'md').should.equal("#{TMP}/hot.md")
    )
  )

  describe('_getJSPath', ->
    it('should get a js file path from cs file path', () ->
      byWrite2JS._getJSPath(HOTCOFFEE).should.equal("#{TMP}/hot.js")
      byWrite2JS._getJSPath(ICEDCOFFEE, MAPPER).should.equal("#{FOO2}/iced.js")
    )
    it('should get a bin path if @opts.bin is set true', () ->
      byWrite2JS = new ByWrite2JS({root:TMP, binDir:FOO, bin: true})
      byWrite2JS._getJSPath(BIN).should.equal(BINJS)
    )

  )
  describe('_writeJS', ->
    it('should write to a js file', (done) ->
      byWrite2JS.on('wrote2js', (data) ->
        data.jsfile.should.equal(ICEDJS)
        done()
      )
      byWrite2JS._writeJS({jsfile:ICEDJS, compiled:COMPILED, file:ICEDCOFFEE})
    )
    it('should put "#!/usr/bin/env node" on the first line if extension is "bin.coffee"', (done) ->
      byWrite2JS = new ByWrite2JS({root:TMP, binDir:FOO, bin: true, nolog: true})
      byWrite2JS.on('wrote2js', (data) ->
        data.jsfile.should.equal(BINJS)
        fs.readFile(BINJS, (err, body) ->
          body.toString().split('\n')[0].should.equal("#!/usr/bin/env node")
          done()
        )
      )
      byWrite2JS._writeJS({jsfile:BINJS, compiled:COMPILED, file:BIN})
    )
  )

  describe('_emitter', ->
    it('emit "wrote2js" event', (done) ->
      byWrite2JS.on('wrote2js', (data) ->
        data.file.should.equal(HOTCOFFEE)
        done()
      )
      byWrite2JS._emitter(null, {file : HOTCOFFEE})
    )
    it('emit "write2js error" event if fail to write', (done) ->
      byWrite2JS.on('write2js error', (data) ->
        data.file.should.equal(HOTCOFFEE)
        done()
      )
      byWrite2JS._emitter(true, {file : HOTCOFFEE})
    )

  )

  describe('_emitWrote', ->
    it('emit "wrote2js" event', (done) ->
      byWrite2JS.on('wrote2js', (data) ->
        data.file.should.equal(HOTCOFFEE)
        done()
      )
      byWrite2JS._emitWrote({file : HOTCOFFEE})
    )
  )
  describe('_emitWriteError', ->
    it('emit "write2js error" event if fail to write', (done) ->
      byWrite2JS.on('write2js error', (data) ->
        data.file.should.equal(HOTCOFFEE)
        done()
      )
      byWrite2JS._emitWriteError(true, {file : HOTCOFFEE})
    )

  )

  describe('rmJS', ->
    it('rm JS file', (done) ->
      fs.writeFile(ICEDJS,COMPILED, () ->
        fs.exists(ICEDJS, (exist) ->
          exist.should.be.ok
          byWrite2JS.on('js removed', (data)->
            data.jsfile.should.equal(ICEDJS)
            done()
          )
          byWrite2JS.rmJS({jsfile: ICEDJS, file: ICEDCOFFEE})
        )
      )  
    )
    it('should emit "unlink error" if no file', (done) ->
      fs.exists(ICEDJS, (exist) ->
        exist.should.not.be.ok
        byWrite2JS.on('unlink error', (data)->
          data.jsfile.should.equal(ICEDJS)
          done()
        )
        byWrite2JS.rmJS({jsfile: ICEDJS, file: ICEDCOFFEE})
      )
    )
  )

  describe('_setListeners', (done) ->
    beforeEach(->
      bystander = new Bystander(TMP,{nolog:true, plugins:['by-coffeescript']})
    )
    it('should listen to "compiled" and write to a js file', (done) ->
      bystander.once('watchset', () ->
        byWrite2JS._setListeners(bystander)
        byWrite2JS.on('wrote2js',(data)->
          if data.jsfile is ICEDJS
            byWrite2JS.removeAllListeners()
            data.file.should.equal(ICEDCOFFEE)
            done()
        )
        fs.utimes(ICEDCOFFEE, Date.now(), Date.now())
      )
      bystander.run()

    )
    it('should listen to "coffee removed" and remove js file as well', (done) ->
      fs.writeFile(ICEDJS, COMPILED, () ->
        bystander.once('watchset', () ->
          byWrite2JS._setListeners(bystander)
          byWrite2JS.on('js removed',(data)->
            if data.jsfile is ICEDJS
              byWrite2JS.removeAllListeners()
              data.file.should.equal(ICEDCOFFEE)
              done()
          )
          fs.unlink(ICEDCOFFEE)
        )
        bystander.run()
      )
    )

  )
)