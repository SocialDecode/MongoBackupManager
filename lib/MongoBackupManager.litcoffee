Mongo Backup Manager
====================

    ###
    # SourceFile in source/index.litcoffee
    ###

##The requied files.

    fs = require 'fs'
    config = require __dirname+'/../configs/defaultConfig.json'

    if fs.existsSync __dirname+'/../configs/config.json'
      customConfig = require __dirname+'/../configs/config.json'
      config[key] = value for key, value of customConfig

    MongoClient = require('mongodb').MongoClient
    spawn = require('child_process').spawn
    require 'consolecolors'


##Lets check if we have some parameters to take in care
    
    opts = require 'nomnom'
      .option 'full', {
        abbr : 'f'
        flag : true
        default : false
        help : 'Set it to do a full dump'
      }
      .option 'zip', {
        abbr : 'z'
        flag : false
        default : true
        help : 'Set it to create a zip file from the dumped data. It will delete the dumped data after zip creation'
      }
      .parse()

    unless opts.full
      config.ignoredCollections.push "comments"

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
      console.log 'Starting dump...'.green
      makeDump 0

##With the collections ready, lets call a process to start dumping

    makeDump = (indexKey)->
      return done() if indexKey is cCollections.length
      console.log '  ✔'.blue, cCollections[indexKey].yellow
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
      console.log 'Dump finished on:'.green,('dumps/'+dumpDir).magenta.underline
      console.log 'Zipping dumped data, this might take a while ...'.yellow

      unless opts.nozip
        zipping = spawn 'zip', ['-9r','dumps/'+dumpDir+'.zip','dumps/'+dumpDir]

        zipping.stderr.on 'data', (data)->
          console.log 'stderr', data
          process.exit 1

        zipping.on 'exit', (code)->
          console.log 'zipping done'.green
          cleaning = spawn 'rm', ['-rf','dumps/'+dumpDir]
          cleaning.on 'exit', (code)->
            process.exit 0
      else
        process.exit 0
