This purpose of this project is to have a daemon that listens in directly to the gmond traffic and can extract the correct structure.

Further purposes are to make it push this information to a message queue and eventually to a historical archival of event/metrics like opentsdb

This is :
- ruby code
- using jruby
- that uses eventmachine
- and the final will be packaged with warbler to a java executable jar to make it easy to distribute and run.

This needs to futher benchmark for a look at performance compared to gmond itself.

Thanks to Vladimir Vuksan to help me with this proof of concept
