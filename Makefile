run:
	DEBUG=* npm start

compile:
	cd public/javascripts; make

push:
	git push

test:
	grunt test

backup:
	mongoexport -d gyazz -c pages >    export/pages.mongoexport
	mongoexport -d gyazz -c accesses > export/accesses.mongoexport
	mongoexport -d gyazz -c attrs >    export/attrs.mongoexport
	mongoexport -d gyazz -c lines >    export/lines.mongoexport
	mongoexport -d gyazz -c pairs >    export/pairs.mongoexport

restore:
	mongoimport -d gyazz -c pages    pages.mongoexport
	mongoimport -d gyazz -c accesses accesses.mongoexport 
	mongoimport -d gyazz -c attrs    attrs.mongoexport 
	mongoimport -d gyazz -c pairs    pairs.mongoexport 
	mongoimport -d gyazz -c lines    lines.mongoexport 
