$(document).ready(function() {

window.MoreRealisticDLCs = {};

// SMOOTH SCROLL
smoothScroll.init({
	speed: 400, // Integer. How fast to complete the scroll in milliseconds
	easing: 'easeInOutCubic', // Easing pattern to use
	updateURL: false, // Boolean. Whether or not to update the URL with the anchor hash on scroll
	offset: 0 // Integer. How far to offset the scrolling anchor location in pixels
	// callbackBefore: function ( toggle, anchor ) {}, // Function to run before scrolling
	// callbackAfter: function ( toggle, anchor ) {} // Function to run after scrolling
});

// BACK TO TOP
var minY = $('header nav').offset().top;
$(window).scroll(function() {
	if ($(this).scrollTop() > minY) {
		$('#backToTop').fadeIn(100).css('display', 'table');
		// $('#backToTop').removeClass('hidden');
	} else {
		$('#backToTop').fadeOut(100);
		// $('#backToTop').addClass('hidden');
	};
});

// LIGHTBOX
var container = $('#container');
var onLightBoxOpen = function() {
	container.addClass('lightBoxOpen').removeClass('lightBoxClosed');
};
var onLightBoxClose = function() {
	container.addClass('lightBoxClosed').removeClass('lightBoxOpen');
};

var activityIndicatorOn = function() {
	$( '<div id="imagelightbox-loading"><div></div></div>' ).appendTo( 'body' );
};
var activityIndicatorOff = function() {
	$( '#imagelightbox-loading' ).remove();
};

var navigationOn = function( instance, selector ) {
	var images = $( selector );
	if( images.length ) {
		var nav = $( '<div id="imagelightbox-nav"></div>' );
		for( var i = 0; i < images.length; i++ )
			nav.append( '<button type="button"></button>' );

		nav.appendTo( 'body' );
		nav.on( 'click touchend', function(){ return false; });

		var navItems = nav.find( 'button' );
		navItems.on( 'click touchend', function()
		{
			var $this = $( this );
			if( images.eq( $this.index() ).attr( 'href' ) != $( '#imagelightbox' ).attr( 'src' ) )
				instance.switchImageLightbox( $this.index() );

			navItems.removeClass( 'active' );
			navItems.eq( $this.index() ).addClass( 'active' );

			return false;
		})
		.on( 'touchend', function(){ return false; });
	};
};
var navigationUpdate = function( selector ) {
	var items = $( '#imagelightbox-nav button' );
	items.removeClass( 'active' );
	items.eq( $( selector ).filter( '[href="' + $( '#imagelightbox' ).attr( 'src' ) + '"]' ).index( selector ) ).addClass( 'active' );
};
var navigationOff = function() {
	$( '#imagelightbox-nav' ).remove();
};

var selector = 'a.galleryImage';
var instance = $( selector ).imageLightbox({
    animationSpeed: 100,
    onStart: function() { onLightBoxOpen(); navigationOn( instance, selector ); },
    onEnd:   function() { onLightBoxClose(); navigationOff(); activityIndicatorOff();  },
	onLoadStart: function() { activityIndicatorOn(); },
	onLoadEnd:   function() { navigationUpdate( selector ); activityIndicatorOff(); }
});

});