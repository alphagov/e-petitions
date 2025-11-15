import * as esbuild from 'esbuild'

const watch = process.argv.includes('--watch')
const minify = process.argv.includes('--minify')
const error = process.argv.includes('--error')

const entryPoints = error
  ? ['app/assets/javascripts/error.js']
  : [
      'app/assets/javascripts/admin.js',
      'app/assets/javascripts/application.js',
      'app/assets/javascripts/cookie-manager.js',
      'app/assets/javascripts/character-counter.js',
      'app/assets/javascripts/signature-form.js',
      'app/assets/javascripts/open-petition.js',
      'app/assets/javascripts/closed-petition.js',
      'app/assets/javascripts/archived-petition.js'
    ]

const context = await esbuild.context({
  entryPoints: entryPoints,
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
