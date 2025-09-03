import * as esbuild from 'esbuild'

const watch = process.argv.includes('--watch')
const minify = process.argv.includes('--minify')

const context = await esbuild.context({
  entryPoints: ['app/assets/javascripts/*.js'],
  bundle: true,
  sourcemap: !minify,
  minify: minify,
  outdir: 'app/assets/builds',
  publicPath: 'assets'
});

if (watch) {
  await context.watch()
} else {
  await context.rebuild()
  context.dispose()
}
