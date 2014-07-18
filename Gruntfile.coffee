'use strict'

module.exports = (grunt) ->

  require 'coffee-errors'

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-simple-mocha'
  grunt.loadNpmTasks 'grunt-notify'
  grunt.loadNpmTasks 'grunt-contrib-coffee'

  grunt.registerTask 'test',    [ 'coffeelint', 'simplemocha' ]
  grunt.registerTask 'default', [ 'test', 'watch' ]
  grunt.registerTask 'compile', [ 'coffee' ]

  grunt.initConfig

    coffeelint:
      options:
        max_line_length:
          value: 119
        indentation:
          value: 2
        newlines_after_classes:
          level: 'error'
        #no_empty_param_list:
        #  level: 'error'
        no_unnecessary_fat_arrows:
          level: 'ignore'
      dist:
        files: [
          { expand: yes, cwd: './', src: [ '*.coffee' ] }
          { expand: yes, cwd: 'models/', src: [ '**/*.coffee' ] }
          { expand: yes, cwd: 'controllers/', src: [ '**/*.coffee' ] }
          { expand: yes, cwd: 'sockets/', src: [ '**/*.coffee' ] }
          { expand: yes, cwd: 'public/', src: [ '**/*.coffee' ] }
        ]

    simplemocha:
      options:
        ui: 'bdd'
        reporter: 'spec'
        compilers: 'coffee:coffee-script'
        ignoreLeaks: no
      dist:
        src: [ 'tests/test_*.coffee' ]

    coffee:
      compile:
        files:
          'public/javascripts/transpose.js': 'public/javascripts/transpose.coffee'
          'public/javascripts/align.js': 'public/javascripts/align.coffee'
      options:
        bare: yes

    watch:
      options:
        interrupt: yes
      dist:
        files: [
          '*.coffee'
          'models/**/*.coffee'
          'controllers/**/*.coffee'
          'sockets/**/*.coffee'
          'public/**/*.{coffee,js,jade}'
          'tests/**/*.coffee'
        ]
        tasks: [ 'test' ]
