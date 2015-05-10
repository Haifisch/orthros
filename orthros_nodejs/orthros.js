/* 
	Something something copyright

	Save for use later;
	var decipher = crypto.createDecipher('aes-256-ctr',pass_conf)
	var dec = decipher.update(crypted,'hex','utf8')
	dec += decipher.final('utf8');

*/
// modules
var fs = require('fs');
var path = require('path'); 
var mkdirp = require('mkdirp');
var colors = require('colors');
var Prompt = require('prompt-improved');
var uuid = require('uuid');
var NodeRSA = require('node-rsa');
var crypto = require('crypto');
var read = require('read');
var request = require('request');
var SegfaultHandler = require('segfault-handler');
var deasync = require('deasync');
var ursa = require('ursa');
// global objects
var AESCrypt = {};
var key = new NodeRSA();
var args = process.argv.slice(2);
var version = "v1.0.0"
var help = "Command line options;"
			+ "\n./orthros send [Recieving UUID] [Message] - Sends supplied message to UUID" 
			+ "\n./orthros check - Checks for messages in queue"
			+ "\n./orthros read [Message ID] - Decrypts and reads message for ID";
var orthros_settings =  process.env['HOME'] + "/.orthros";
var orthros_config = orthros_settings + "/config.json";
var orthros_api_url = "http://orthros.ninja/api/bithash.php?"

var prompt = new Prompt({
    prefix        : '',
    suffix        : ': ',
    defaultPrefix : ' (',
    defaultSuffix : ')',
    textTheme     : Prompt.chalk.bold,
    prefixTheme   : Prompt.chalk.white,
    suffixTheme   : Prompt.chalk.white,
    defaultTheme  : Prompt.chalk.white,
    inputError    : 'Error encountered, try again.',
    requiredError : 'Required! Try again.',
    invalidError  : 'Invalid input: ',
    attemptsError : 'Maximum attempts reached!',
    stdin         : process.stdin,
    stdout        : process.stdout,
    stderr        : process.stderr,
    timeout       : null
});

AESCrypt.decrypt = function(cryptkey, iv, encryptdata) {
    encryptdata = new Buffer(encryptdata, 'base64').toString('binary');
 
    var decipher = crypto.createDecipheriv('aes-256-cbc', cryptkey, iv),
        decoded  = decipher.update(encryptdata);
 
    decoded += decipher.final();
    return decoded;
}
 
AESCrypt.encrypt = function(cryptkey, iv, cleardata) {
    var encipher = crypto.createCipheriv('aes-256-cbc', cryptkey, iv),
        encryptdata  = encipher.update(cleardata);
 
    encryptdata += encipher.final();
    encode_encryptdata = new Buffer(encryptdata, 'binary').toString('base64');
    return encode_encryptdata;
}
/* Configuration check functions */
function checkConfigDirectory (callback) {
	fs.exists(orthros_settings, function(exists) {
	    if (!exists) {
	        mkdirp(orthros_settings, function(err) { 
	        	if (err) {console.log("Error settings directory in; " + orthros_settings); callback(false);};
	        	callback(true);
			});
	    } else {
	    	callback(true);
	    }
	});
}

function getConfigFile (callback) {
	fs.readFile(orthros_config, {encoding: 'utf-8'}, function(err,data){
		if (err) {
			callback(null);
		} else {
			var configParsed = JSON.parse(data);
			if (configParsed["uuid"] === null){
		    	callback(null);
			} 
			callback(configParsed);
		}
	});
	
}

/* Orthros API b2b functions */
function uuid_from_config (callback) {
	var configFile = getConfigFile(function (parsedConfig) { 
		if (parsedConfig === null) {
			callback(null); // this shouldn't happen if the main function catches that the config doesn't exsist
		} else {
			callback(parsedConfig["uuid"]);
		};
	});
}

function all_msgs_in_que (uuid, callback) {
	request.get(orthros_api_url+'action=list&UUID='+uuid, function(error, response, body) {
		var parsedRes = JSON.parse(body);
		if (parsedRes["error"] == 1) {
		  	console.log("No messages found!");
		  	callback(null);
		} else if (parsedRes["error"] == 0) {
		  	console.log("Messages in que;".green);
		  	var msgs = parsedRes["msgs"];
		  	callback(msgs);
		};
	});
}

function sender_for_msg (msg_id, uuid, callback) {
	request.get(orthros_api_url+'action=get&UUID='+uuid+'&msg_id='+msg_id, function(error, response, body) {
		var parsedRes = JSON.parse(body);
		if (parsedRes["msg"]) {
			callback([msg_id,parsedRes["msg"]["sender"]]);
		};
	});
}

function check_for_messages (argument) {
	var uuidFromConfig = uuid_from_config(function (uuid_ret) { 
		if (uuid_ret === null) {
			console.log("We're missing the user uuid!".red);
		} else {
			var msgs = all_msgs_in_que(uuid_ret, function (msgs_qued) {
				for (var i = 0; i < msgs_qued.length; i++) {
					sender_for_msg(msgs_qued[i], uuid_ret, function (sender) {
						console.log(('Msg ID: '+sender[0]).blue)
						console.log(('	From: '+sender[1]).green);
					})
				};
			})
		};
	});
}

function get_private_key (callback) {
	read({ prompt : 'Decrypt password:', silent : true }, function (err, pass) {
		if (pass.length > 10) {
			read({ prompt : 'Confirm password: ', silent : true }, function (err, pass_conf) {
				if (pass == pass_conf) {
					var configFile = getConfigFile(function (parsedConfig) { 
						if (parsedConfig === null) {
							console.log("Private key not found!");
						} else {
							var decipher = crypto.createDecipher('aes-256-ctr',pass_conf)
							var dec = decipher.update(parsedConfig["priv"],'hex','utf8')
							dec += decipher.final('utf8');
							callback(dec)
						};
					});

				} else {
					console.log("Passwords don't match! Try again.".red);
				};
			});
		} else {
			console.log("Password must be at least 10 characters.".red);
		}
	});
}

function read_message (msg_id) {
	var uuidFromConfig = uuid_from_config(function (uuid_ret) { 
		if (uuid_ret === null) {
			console.log("We're missing the user uuid!".red);
		} else {
			request.get(orthros_api_url+'action=get&UUID='+uuid_ret+'&msg_id='+msg_id, function(error, response, body) {
				var parsedRes = JSON.parse(body);
				if (parsedRes["msg"]) {
					var crypted_msg = parsedRes["msg"]["msg"];
					crypted_msg = crypted_msg.replace(/ /g,"+");
					var privatekey = get_private_key(function (key) {
						ursa_key = ursa.createPrivateKey(key);
						var dec_msg = ursa_key.decrypt(crypted_msg, 'base64', 'utf8', ursa.RSA_PKCS1_PADDING);
						console.log("Message: ".green + dec_msg)
					});
				};
			});
		};
	});
}

function setupAccount (argument) {
	prompt.ask([{
		question: 'Would you like to create one now?',
		key: 'answer-key',
		attempts: 3,
		required: true,
	    default: 'Y',
	    validate: /^(?:y(?:es)?|n(?:o)?)$/i,
	    after: function(value) {
	        value = value.toLowerCase();
	        if (value === 'y' || value === 'yes') return true;
	        return false;
	    }
		}], function(err, res) {
	    if (err) return console.error(err);
	    if (res["answer-key"] == true) {
	    	var gen_uuid = uuid.v4();
	    	console.log("Generating keys...".green);
	    	key.generateKeyPair(1024, 65537);
	    	read({ prompt : 'Set a password (10 character minumum, don\'t forget this!):', silent : true }, function (err, pass) {
	    		if (pass.length > 10) {
	    			read({ prompt : 'Confirm password: ', silent : true }, function (err, pass_conf) {
						if (pass == pass_conf) {
							var cipher = crypto.createCipher('aes-256-ctr',pass_conf)
							var crypted = cipher.update(key.exportKey('private'),'utf8','hex')
							crypted += cipher.final('hex');
						    var user_config = {"uuid":gen_uuid, "public_key":key.exportKey('public'), "priv":crypted};
							console.log("Submitting public key to server");
							request.post({
							  headers: {'content-type' : 'application/x-www-form-urlencoded'},
							  url:     orthros_api_url+'action=upload&UUID='+user_config["uuid"],
							  body:    "pub="+key.exportKey('public')
							}, function(error, response, body){
							  if (JSON.parse(body)["error"] == 0) {
							  	console.log("Successfully submitted!".green);
							  	fs.writeFile(orthros_config, JSON.stringify(user_config), function(err) {
									if(err) {
										return console.log(err);
									}
									console.log("Config created successfully!".green);
								});
							  };
							});

						} else {
							console.log("Passwords don't match! Try again.".red);
						};
					});
	    		} else {
	    			console.log("Password must be at least 10 characters.".red);
	    		}
			});
		} else {
		   console.log("Goodbye!");
		}
	});
}

/* Used by main */
function checkArgs () {
	if (args.length > 0) {
		if (args[0] == "send") {
			console.log("going to send.")
		} else if (args[0] == "check") {
			check_for_messages();
		} else if (args[0] == "read") {
			if (args[1] == null) {
				console.log("We're missing the message ID!".red)
			} else {
				console.log("Retrieving message: "+args[1])
				read_message(args[1]);
			}
		}
	} else {
		console.log(help);
	}
}

function main (argument) {
	// Check for folder, if none exsist, make it. 
	console.log(("Orthros Messenger " + version).bgMagenta);
	var checkDir = checkConfigDirectory(function (doesExsist) {
		if (doesExsist == true) {
			var configFile = getConfigFile(function (parsedConfig) { 
				if (parsedConfig === null) {
					console.log("We're missing the user config!".red);
					setupAccount();
				} else {
					checkArgs();
				};
			});
		};
	});
}

main();