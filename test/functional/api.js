/**
 * HipStack default tests.
 *
 */
module.exports = {
  HipStack: {

    "Testing /functional": checkAsset( "/test/functional/index.php" )

  }
};


function checkAsset( url ) {

  var request = require( 'request' );

  return function( done ) {
    console.log( 'checkURL', url );

    var _url = [ 'http://0.0.0.0' ];

    if( process.env.CI_HIPSTACK_CONTAINER_PORT ) {
      _url.push( ':', process.env.CI_HIPSTACK_CONTAINER_PORT )
    } else {
      _url.push( ':', 49180 );
    }

    _url.push( url );

    _url = _url.join( '' );

    console.log( 'url', _url );

    request({
      url: _url,
      method: 'GET'
    }, function( error, req, body ) {

      req.should.have.property( 'headers' );
      req.headers.should.have.property( 'content-type' );
      req.headers.should.have.property( 'x-powered-by' );


      if( done ) {
        return done();
      }

    })

    //done();

  }

}
