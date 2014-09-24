
module.exports = function(grunt) {
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),

        //=====================================
        //== Run blocking tasks concurrently ==
        //=====================================
        

        //=================
        //== Watch files ==
        //=================
        

        //========================
        //== File concatination ==
        //========================
        

        //======================
        //== CSS minification ==
        //======================
        

        //=============================
        //== Javascript minification ==
        //=============================
        

        //=========================================
        //== Clear the Production-like directory ==
        //=========================================
        

        //====================================================
        //== Copy server files to Production-like directory ==
        //====================================================
        
 
        //====================
        //== Shell commands ==
        //====================
        

    });

    //=============================
    //== Load Grunt NPM packages ==
    //=============================
    require('load-grunt-tasks')(grunt);

    //====================
    //== Register tasks ==
    //====================
    //== Default task (blank for now)
    grunt.registerTask('default', ['']);
    //== Dev task (Automate the dev environment)
    grunt.registerTask('dev', ['concurrent:dev']);
    //== Production build (Create fresh production-like build)
    grunt.registerTask('build',  ['concat', 'cssmin', 'uglify', 'clean', 'copy', 'shell:prodCommands']);
    
};