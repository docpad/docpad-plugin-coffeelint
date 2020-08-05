# Export Plugin
module.exports = (BasePlugin) ->
	# Requires
	coffeelint = require('coffeelint')
	colors = require('colors')
	merge = require('merge')
	fs = require('fs')
	pathUtil = require('path')

	# Define Plugin
	class CoffeeLintPlugin extends BasePlugin
		# Plugin name
		name: 'coffeelint'

		# Plugin config
		config:
			ignorePaths: [ ]
			ignoreFiles: [ ]
			lintOptions: { }

		# Render Before
		# Called just just after we've rendered all the files.
		renderBefore: ({collection}) ->
			if @docpad.getEnvironment() is 'development'
				config = @config
				ignoredPaths = [ ]

				# Read .coffeelintrc
				fs.readFile process.cwd() + '/.coffeelintrc', (err, data) ->
					if err
						return
					else
						coffeelintrc = JSON.parse(data)
						merge(config.lintOptions, coffeelintrc)

				# Set max errors
				if config.lintOptions.maxerr
					maxErrors = config.lintOptions.maxerr
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

				# this is necessary to work on windows
				ignoredPaths = ignoredPaths.map(pathUtil.normalize)
				config.ignoreFiles = config.ignoreFiles.map(pathUtil.normalize)

				collection.each (item) ->
					file = item.attributes

					# Find coffee files
					if file.extension is 'coffee'
						# Skip files in ignored paths
						for path in ignoredPaths
							if file.relativePath.indexOf(path) is 0
								return

						# Skip ignored files
						for fileName in config.ignoreFiles
							if file.relativePath is fileName
								return
						# Skip valid files
						errors = coffeelint.lint(file.source, config.lintOptions)
						if errors.length is 0
							return

						else
							# Print filename
							console.log 'CoffeeLint - '.white + file.relativePath.red
							coffeelint.errors = errors
							# Print errors
							for err in coffeelint.errors
								ref = 'line ' + err.lineNumber
								message = err.message
								console.log ref.blue + ' - '.white + message

							# Line break between each file
							console.log '\n'
