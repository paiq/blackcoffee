#!/usr/bin/env node

Fs = require 'fs'
Path = require 'path'
lib = Path.join Path.dirname(Fs.realpathSync(__filename)), '../lib/coffee-script'
Coffee = require "#{lib}/coffee-script"
Nodes = require "#{lib}/nodes"
SourceMap = require "#{lib}/sourcemap"
Macro = require "#{lib}/macro"

args = process.argv.slice 2
flags = root.flags = {}

i = 0
while i<args.length
	arg = args[i++]
	continue if arg[0]!='-' # an input file
	args.splice --i, 1
	break if arg=='--'
	if arg=='-o' # output file
		output = args[i]
		args.splice i, 1
	else if arg=='-m' # srcMap file
		map = args[i]
		args.splice i, 1
	else if arg=='-f' # flag
		flag = args[i].split '='
		flags[flag[0]] = flag[1] ? true
		args.splice i, 1
	else
		process.stderr.write "invalid option '#{arg}'\n"
		process.exit 1

asts = []
for file in args
	cs = Fs.readFileSync(file).toString()
	asts.push Coffee.nodes cs, {filename: file}
	# make output executable if at least one of the inputs is
	executable = executable || Fs.statSync(file).mode & (1<<6)

ast = new Nodes.Block(asts)
ast = Macro.expand(ast, Coffee.nodes)
fragments = ast.compileToFragments()
js = (fragment.code for fragment in fragments).join('')
js = "#!/usr/bin/env node\n"+js if executable

if output
	Fs.writeFileSync output, js, {flag: "w", mode: if executable then 0o770 else 0o660}
else
	process.stdout.write js

if map
    sourceMap = new SourceMap fragments
    sourceMap = sourceMap.generate {inline: true}
    Fs.writeFileSync map, sourceMap, null, "w"

