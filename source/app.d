import std.datetime;
import std.conv;
import std.array;
import std.stdio;
import std.string : format;
import vibe.core.log;

// https://code.dlang.org/packages/vibe-mqtt
import mqttd;

string genRndString(int n_digits)
{
    import std.algorithm, std.random, std.range;
    import std.digest : toHexString;	

    return rndGen().map!(a => cast(ubyte) a)().take(n_digits).array.toHexString!(LetterCase.lower);
}

int mqttTest(string host, ushort port)
{
	import vibe.core.core : sleep, runTask;
	import vibe.core.core : runEventLoop;

	auto settings = Settings();
	settings.host = host;
	settings.port = port;
	settings.clientId = "mqtt-client-" ~ genRndString(8);
	settings.reconnect = 1; // s
	settings.keepAlive = 10; // s
	settings.onPublish = (scope MqttClient ctx, in Publish packet)
	{
		logInfo("MQTT received \"" ~ packet.topic ~ "\": \"" ~ (cast(const char[]) packet.payload).idup ~ "\"");
	};
	settings.onConnAck = (scope MqttClient ctx, in ConnAck ack)
	{
		if (ack.returnCode != ConnectReturnCode.ConnectionAccepted) {
			logError("MQTT connection error: %s", ack.returnCode);
			return;
		}
		logInfo("MQTT connected!");

		ctx.subscribe(["test/#"], QoSLevel.QoS2);

		auto publisher = runTask(() nothrow
			{
				try {
					int cntr = 0;

					ctx.publish("test", "42", QoSLevel.QoS2);

					while (ctx.connected)
					{
						logDiagnostic("Publishing...");

						ctx.publish("test/counter", to!string(cntr++), QoSLevel.QoS2);

						sleep(50.msecs);
					}
				} catch (Exception e) {
					logError(e.msg);
				}
			}
		);


	};

	auto mqtt = new MqttClient(settings);
	logInfo("Connecting to %s:%d... ", settings.host, settings.port);
	mqtt.connect();
	scope (exit) mqtt.disconnect();

	return runEventLoop();
}

int main(string[] args)
{
	import vibe.core.log : setLogFormat, FileLogger, setLogLevel, LogLevel;
	import std.getopt;

	ushort port = 1883;
	string host = "127.0.0.1";
	bool trace;
	LogLevel logLevel = LogLevel.info;

	auto helpInfo = getopt(args,
		"port", format("MQTT broker port (default: %d)", port), &port,
		"host", format("MQTT broker host (default: %s)", host), &host,
		"loglevel", format("log level (critical|debug_|debugV|diagnostic|error|info|trace, default: %s)", logLevel), &logLevel
	);

	if (helpInfo.helpWanted) {
		defaultGetoptPrinter("MQTT Dlang test app", helpInfo.options);
		return 1;
	}
	
	setLogFormat(FileLogger.Format.threadTime);
	setLogLevel(logLevel);

	return mqttTest(host, port);
}

