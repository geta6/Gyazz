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
        # files: [
        #   src: 'public/javascripts/*.coffee'
        #   #dest: 'public/javascripts/'
        #   expand: true
        #   ext: '.js'
        #  ]
        # #src: ['public/javascripts/*.coffee']
        # # dest: 'Resources/'
        # # ext: '.js'
        # #
        files:
          'public/javascripts/gyazz_transpose.js': 'public/javascripts/gyazz_transpose.coffee'
          'public/javascripts/gyazz_align.js': 'public/javascripts/gyazz_align.coffee'
          'public/javascripts/gyazz_related.js': 'public/javascripts/gyazz_related.coffee'
          'public/javascripts/gyazz_tag.js': 'public/javascripts/gyazz_tag.coffee'
          'public/javascripts/gyazz_notification.js': 'public/javascripts/gyazz_notification.coffee'
          'public/javascripts/gyazz_edit.js': 'public/javascripts/gyazz_edit.coffee'
          'public/javascripts/gyazz_buffer.js': 'public/javascripts/gyazz_buffer.coffee'
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
