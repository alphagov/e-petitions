module.exports = {
    // output to an ERB file so can be consumed by 'serviceworker-rails' gem
    swDest: 'app/assets/javascripts/serviceworker.js.erb',
    // globbing only used for pre-caching
    globDirectory: '.',
    globPatterns: [],
    // only allow caching of files under 1MB
    maximumFileSizeToCacheInBytes: 1 * 1024 * 1024,
    // use CDN version of WB (can also be local or disabled)
    importWorkboxFrom: 'cdn',
    // claim any browser tabs that are running immediately
    clientsClaim: true,
    // skip the wait and init immediately
    skipWaiting: true,
    // define custom caching routes for more flexibility
    runtimeCaching: [
        // HTML will always be served from the network
        {
            urlPattern: new RegExp('.*\.html'),
            handler: 'NetworkOnly'
        },
        // Analytics always comes from the network
        {
            urlPattern: new RegExp('https://www.(?:googletagmanager|google-analytics).com/(.*)'),
            handler: 'NetworkOnly'
        },
        // JSON file to update the counter always comes from the network
        {
            urlPattern: new RegExp('count.json'),
            handler: 'NetworkOnly'
        },
        // CSS / JS assets using cache first strategy since filenames are revisioned
        {
            urlPattern: new RegExp('.*.(?:css|js)'),
            handler: 'CacheFirst',
            options: {
                cacheName: 'parliament-petitions-application-cache-',
                // assets only cached for 30 days ensuring older revisions clear out after this time
                expiration: {
                    maxAgeSeconds: 30 * 24 * 60 * 60
                }
            }
        },
        // Image assets using cache first strategy since filenames are revisioned
        {
            urlPattern: new RegExp('.*.(?:png|jpg|jpeg|ico|gif)'),
            handler: 'CacheFirst',
            options: {
                cacheName: 'parliament-petitions-image-cache-',
                // assets only cached for 30 days ensuring older revisions clear out after this time
                expiration: {
                    maxAgeSeconds: 30 * 24 * 60 * 60
                }
            }
        }
    ]
};