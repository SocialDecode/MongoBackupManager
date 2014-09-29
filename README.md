MongoBackupManager
==================

Configurable and flexible mongoDB backup generator.  
Have a big mongoDB that needs a backup or a dump? But you dont want to dump the whole DB, maybe you have a couple of collections that are way too big and useless to backup.  
Nobody wants to start a dump for every single collection that needs to be saved.  
With this you can specify a collection or several collections to skip from the dump.

##Configuration
A sample config file is provided on `source/defaultConfig.json`  
Just copy/paste the file on root with name `config.json` and set your preferences.  
If no `config.json` file is provided, the default will be used.

##Usage
Some dependencies are needed, just use:  

    npm install

and you can start dumping with:  

    npm start


All output will be sent to `dumps/<year>-<month>-<day>-<epoch>/`  
From there you can simply do:

    cd dumps
    mongorestore <dumpfolder>

To restore a snapshot dumpfile when needed


##Development and debug
There is only one file to edit in `source/index.litcoffee`, remember to start the gruntfile on root to compile.