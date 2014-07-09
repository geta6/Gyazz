# Gyazzの再実装

Node, Express, MongoDBで再実装するので助けて下さい (増井)

Gyazzデータは [https://github.com/masui/Gyazz]() の
Gyazz/admin/gyazz2mongo で MongoDBデータに変換できます

mongoexportしたものをどこかに置いておきます


[![Build Status](https://travis-ci.org/masuilab/Gyazz.svg?branch=master)](https://travis-ci.org/masuilab/Gyazz)


# Install Dependencies

    % npm i


## 起動

    % PORT=3000 npm start

## Debug

    % PORT=3000 DEBUG=gyazz* npm start


## Test

    % npm test
    or
    % grunt