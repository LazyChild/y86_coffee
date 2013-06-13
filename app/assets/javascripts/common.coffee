requirejs.config
    baseUrl: '/assets/javascripts/lib',
    paths:
        app: '../app'
        jquery: 'jquery-1.9.0.min',
        kinetic: 'kinetic-v4.5.2.min'
        FileSaver: 'FileSaver.min'
    shim:
        kinetic:
            exports: 'Kinetic'
        FileSaver:
            exports: 'saveAs'

