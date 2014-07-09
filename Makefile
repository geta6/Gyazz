run:
	DEBUG=* npm start

backup:
	mongoexport -d gyazz -c pages > export/masuilab.mongoexport
