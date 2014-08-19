'use strict'

module.exports = (grunt) ->

  require 'coffee-errors'

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-csslint'
  grunt.loadNpmTasks 'grunt-jsonlint'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-simple-mocha'
  grunt.loadNpmTasks 'grunt-notify'
  grunt.loadNpmTasks 'grunt-contrib-coffee'

  grunt.registerTask 'test', [
    'coffeelint'
    'simplemocha'
    'jsonlint'
    'csslint'
  ]
  grunt.registerTask 'default', [ 'test', 'build', 'watch' ]
  grunt.registerTask 'build',   [ 'coffee' ]

  grunt.initConfig

    csslint:
      strict:
        src: [
          # '**/*.css'
          '**/gyazz.css'
          '!node_modules/**'
        ]

    jsonlint:
      config:
        src: [
          '**/*.json'
          '!node_modules/**'
          '!tmp/**'
        ]

    coffeelint:
      options:
        max_line_length:
          value: 119
        indentation:
          value: 2
        newlines_after_classes:
          level: 'error'
        no_empty_param_list:
          level: 'error'
        no_unnecessary_fat_arrows:
          level: 'ignore'
      dist:
        files:
          src: [
            '**/*.coffee'
            '!node_modules/**'
            '!tmp/**'
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
        files: [{
          expand: yes
          cwd: 'public/javascripts/'
          src: [ '**/*.coffee' ]
          dest: 'public/javascripts/'
          ext: '.js'
        }]
        options: {
          sourceMap: yes
        }

    watch:
      options:
        interrupt: yes
      dist:
        files: [
          '**/*.{coffee,js,jade}'
          '!node_modules/**'
          '!tmp/**'
          '!public/**/*.js'
        ]
        tasks: [ 'test', 'build' ]
