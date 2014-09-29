module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'

  grunt.registerTask('default',['watch'])

  grunt.initConfig {
    coffee:{
      options :{
        bare : true
      }
      app:{
        files : {
          'index.js' : ['source/index.litcoffee']
        }
      }
    }

    watch:{
      coffee : {
        files: ['source/index.litcoffee']
        tasks: ['coffee']
      }
    }
  }