var mongoose = require('mongoose');

mongoose.connect('mongodb://localhost/test2', function(err) {
  if (err) { return; }
  console.log("connect MongoDB");
});

var UserSchema = new mongoose.Schema({
  name:  String,
  point: Number
});

var User = mongoose.model('uSER', UserSchema);

//var user = new User();
//user.name  = 'KrdLab';
//user.point = 778;
//user.save(function(err) {
//  if (err) { console.log(err); }
//});

User.find({}, function(err, results){
  if (err) {
    console.log('ERROR');
  } else {
    console.log(results);
  }
});


