
/*
 * SourceFile in source/index.litcoffee
 */
var MongoClient, cCollections, cleanCollections, conSettings, config, customConfig, dbConnectionString, done, dumpCollection, dumpDir, fs, key, makeDump, spawn, value;

fs = require('fs');

config = require(__dirname + '/source/defaultConfig.json');

if (fs.existsSync(__dirname + '/config.json')) {
  customConfig = require(__dirname + '/config.json');
  for (key in customConfig) {
    value = customConfig[key];
    config[key] = value;
  }
}

MongoClient = require('mongodb').MongoClient;

spawn = require('child_process').spawn;

conSettings = config.dbConnection;

dbConnectionString = 'mongodb://' + conSettings.uri + ':' + conSettings.port + '/' + conSettings.dbName + '?' + conSettings.uriOptions;

MongoClient.connect(dbConnectionString, function(err, db) {
  var collections;
  if (err) {
    throw err;
  }
  collections = [];
  db.collectionNames(function(err, cols) {
    var collection, _i, _len;
    for (_i = 0, _len = cols.length; _i < _len; _i++) {
      collection = cols[_i];
      collections.push(collection.name.replace(conSettings.dbName + '.', ''));
    }
    db.close();
    return cleanCollections(collections);
  });
});

cCollections = [];

dumpDir = '';

cleanCollections = function(collections) {
  var col, date, day, epoch, month, year, _i, _len;
  for (_i = 0, _len = collections.length; _i < _len; _i++) {
    col = collections[_i];
    if (config.ignoredCollections.indexOf(col) === -1) {
      cCollections.push(col);
    }
    if (config.requiredCollections.indexOf(col) !== -1) {
      cCollections.push(col);
    }
  }
  cCollections = cCollections.filter(function(value, index, self) {
    return self.indexOf(value) === index;
  });
  date = new Date();
  year = date.getFullYear();
  month = ('0' + (date.getMonth() + 1)).slice(-2);
  day = ('0' + date.getDate()).slice(-2);
  epoch = ~~(date.getTime() / 1000);
  dumpDir = [year, month, day, epoch].join('-');
  console.log('Starting dump', 'on: dumps/' + dumpDir);
  return makeDump(0);
};

makeDump = function(indexKey) {
  if (indexKey === cCollections.length) {
    return done();
  }
  console.log('  # dumping', cCollections[indexKey]);
  return dumpCollection(cCollections[indexKey], indexKey);
};

dumpCollection = function(col, key) {
  var args, mongodump;
  args = ['--host', conSettings.uri, '--port', conSettings.port, '--db', conSettings.dbName, '--collection', col, '--out', 'dumps/' + dumpDir];
  mongodump = spawn('mongodump', args);
  mongodump.stderr.on('data', function(data) {
    return console.log('stderr', data);
  });
  return mongodump.on('exit', function(code) {
    return makeDump(key + 1);
  });
};

done = function() {
  console.log('Dump Finished');
  return process.exit(0);
};
