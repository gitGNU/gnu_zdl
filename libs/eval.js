var a = process.argv.slice(2);
var vm = require('vm');
var context = vm.createContext();
var script = new vm.Script(a[0]);
console.log(script.runInNewContext(context));

//////// ALTERNATIVE VERSION:
//
// var a = process.argv.slice(2);
// eval("var out=String" + a[0]);
// console.log(out);

