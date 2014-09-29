Mongo Backup Manager
====================

    ###
    # SourceFile in source/index.litcoffee
    ###

##The requied files.

    fs = require 'fs'
    config = require __dirname+'/source/defaultConfig.json'

    if fs.existsSync __dirname+'/config.json'
      customConfig = require __dirname+'/config.json'
      config[key] = value for key, value of customConfig

    MongoClient = require('mongodb').MongoClient
    spawn = require('child_process').spawn


##Lets gather all the collections to work with.

    conSettings = config.dbConnection
    dbConnectionString = 'mongodb://'+
      conSettings.uri+':'+
      conSettings.port+'/'+
      conSettings.dbName+'?'+
      conSettings.uriOptions

    MongoClient.connect dbConnectionString, (err,db)->
      throw err if err
      collections = []
      db.collectionNames (err,cols)->
        for collection in cols
          collections.push collection.name.replace(conSettings.dbName+'.','')
        db.close()
        cleanCollections collections
      return

##Lets clean the array of collections to use only the ones we want.

    cCollections = []
    dumpDir = ''
    cleanCollections = (collections)->
      for col in collections
        if config.ignoredCollections.indexOf(col) is -1
          cCollections.push col
        if config.requiredCollections.indexOf(col) isnt -1
          cCollections.push col

      cCollections = cCollections.filter (value,index,self)->
        return self.indexOf(value) is index

##Here we set the directory where our dump is going to be saved.

      date = new Date()
      year = date.getFullYear()
      month = ('0'+(date.getMonth()+1)).slice(-2)
      day = ('0'+date.getDate()).slice(-2)
      epoch = ~~(date.getTime()/1000)
      dumpDir = [year,month,day,epoch].join('-')
      console.log 'Starting dump', 'on: dumps/'+dumpDir
      makeDump 0

##With the collections ready, lets call a process to start dumping

    makeDump = (indexKey)->
      return done() if indexKey is cCollections.length
      console.log '  # dumping', cCollections[indexKey]
      dumpCollection cCollections[indexKey], indexKey

##This is the actual worker

    dumpCollection = (col,key)->

      args = [
        '--host',       conSettings.uri,
        '--port',       conSettings.port,
        '--db',         conSettings.dbName,
        '--collection', col,
        '--out',        'dumps/'+dumpDir
      ]
      mongodump = spawn 'mongodump',args

      mongodump.stderr.on 'data', (data)->
        console.log 'stderr', data
      mongodump.on 'exit', (code)->
        makeDump key+1

##Just exiting here

    done = ()->
      console.log 'Dump Finished'
      process.exit 0