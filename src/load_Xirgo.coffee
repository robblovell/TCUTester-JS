
MAXTHREADS = 10

PORT = 9001
assert = require('assert')
Buffer = require('buffer').Buffer
dgram = require('dgram')

debug = true
tests_run = 0
start = []
end = []

start[ix] = new Date().getTime() for ix in [0..MAXTHREADS+1]
end[ix] = new Date().getTime() for ix in [0..MAXTHREADS+1]
count = [];
count[ix]=0 for ix in [0..MAXTHREADS+1]
N = 50;
server = null

sendMessage = (port, host, ix, callback=null) ->
    buf = new Buffer('$$358901049078311,4050,1,1,1,503.6,139.4,3,0,14,14,0,0,0,0,0,61,511544,79596,0,0,0,0,050##')
    client = dgram.createSocket('udp4')

    client.on('message', (msg, rinfo) ->
        end[ix] = new Date().getTime()

        time = end[ix] - start[ix]
        console.log('Execution time: ' + time)

        if (debug)
            console.log('client got: ' + msg + ' from ' + rinfo.address + ':' + rinfo.port)
        #assert.equal('PONG', msg.toString('ascii'))

        count[ix] += 1

        start[ix] = new Date().getTime()

        if (count[ix] < N)
            console.log("client "+ix+" count:"+count[ix]+" sending: "+msg)
            client.send(buf, 0, buf.length, port, '10.0.0.39')
        else
            console.log("client "+ix+" count:"+count[ix]+" done: "+msg)
            setTimeout(() ->
                client.close()
                callback(null, "finished") if callback?
            , 100
            )
    )

    client.on('close', () ->
        console.log('client has closed, closing server')
        tests_run += 1
    )

    client.on('error', (e) ->
        throw e
    )

    console.log('Client sending to ' + port + ', 10.0.0.39 ' + buf)

    client.send(buf, 0, buf.length, port, '10.0.0.39', (err, bytes) ->
        if (err)
            throw err

        console.log('Client sent ' + bytes + ' bytes');
    )
    count[ix] += 1

tcuTest = (port, host, callback) ->
    callbacks = 0;

    server = dgram.createSocket('udp4', (msg, rinfo) ->
        if (debug)
            console.log('server got: ' + msg + ' from ' + rinfo.address + ':' + rinfo.port)

        if (/PING/.exec(msg))
            buf = new Buffer(4)
            buf.write('PONG');
            server.send(buf, 0, buf.length,
                rinfo.port, rinfo.address,
                (err, sent) ->
                    callbacks++
            )
    )

    server.on('error', (e) ->
        throw e
    )

    server.on('message', (msg, rinfo) ->
        console.log('server got: ' + msg + ' from ' + rinfo.address + ':' + rinfo.port)
    )

    server.on('listening', () ->
        console.log('server listening on ' + port + ' ' + host);

        sendMessage(port, host, i) for i in [0..MAXTHREADS]
        sendMessage(port, host, 101, callback)

    )
    server.bind(port, host)

# All are run at once, so run on different ports
tcuTest(PORT, '0.0.0.0', (error, result) ->
    console.log('done1')
    server.close()
)

process.on('exit', () ->
    console.log("Count: "+count[ix]) for ix in [0..MAXTHREADS]
    console.log('done2')
)