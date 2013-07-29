# Export Plugin
module.exports = (BasePlugin) ->
  # Requires
  coffeelint = require('coffeelint')
  colors = require('colors')

  # Define Plugin
  class CoffeeLintPlugin extends BasePlugin
    # Plugin name
    name: 'coffeelint'

    # Plugin config
    config:
      ignorePaths: [ ]
      ignoreFiles: [ ]
      ignoreMinified: true
      globals: { }       # additional predefined global variables
      hintOptions: { }
    
      # Render After
      # Called just just after we've rendered all the files.
    renderAfter: ({collection}) ->
      if docpad.getEnvironment() is 'development'
        config = @config
        ignoredPaths = [ ]
        if config.hintOptions.maxerr
          maxErrors = config.hintOptions.maxerr
        else
          maxErrors = 50
   
        # Normalize ignored paths
        config.ignorePaths.map (path, i) =>
          path = path.toString()
          if path.charAt(0) is '/'
            path.slice(1)
          if path.charAt(path.length - 1) isnt '/'
            path = path + '/'
          ignoredPaths.push(path)

        collection.each (item) ->
          file = item.attributes
          tooManyErrors = false
          
          # Find JS files
          if file.extension is 'js'
            
            # Skip files in ignored paths
            for path in ignoredPaths
              if file.relativePath.indexOf(path) is 0
                return
            
            # Skip ignored files
            for fileName in config.ignoreFiles
              if file.relativePath is fileName
                return

            # Skip minified files (based on .min.js convention)
            if config.ignoreMinified
              if file.relativePath.indexOf('.min.js') isnt -1
                return

            # Skip valid files
            if coffeelint(file.source, config.options, config.globals) is true
              return

            else
              # Print filename
              console.log 'coffeelint - '.white + file.relativePath.red
              
              # Trim errors down to max to prevent failure
              if coffeelint.errors.length > maxErrors
                tooManyErrors = true
                while coffeelint.errors.length > maxErrors
                  coffeelint.errors.pop()
              
              # Print errors
              for err in coffeelint.errors
                ref = 'line ' + err.line + ', char ' + err.character
                message = err.reason
                console.log ref.blue + ' - '.white + message
              
              # Print warning if coffeelint,errors was > maxerr
              if tooManyErrors
                console.log('Too many errors.'.underline.yellow)
              
              # Line break between each file
              console.log '\n'
