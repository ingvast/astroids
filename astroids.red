RED [
	needs: 'view
]

size: 800x800
time-step: to-time 0.05

ship: make object! [

    speed: [ 0  0 ]
    pos: reduce [ size/x / 2 size/y / 2 ]
    rot: 0

    graphic: reduce [
	'translate to-pair pos
	'rotate rot
	'fill-pen green
	'pen yellow
	'polygon 0x-30 10x10 0x0 -10x10
    ]

    wall-reactions: context [
	wall-thickness: 30
	k: 1.5
	c: 0.2 * k
	reaction: func [ x v ] [
	     max 0 negate x * k  + ( v * c )
	]
	left: func [ pos speed ][
	    reaction pos/1 - wall-thickness speed/1
	]
	right: func [ pos speed][
	    negate reaction size/x - wall-thickness - pos/1 negate speed/1
	]
	top: func [ pos speed ][
	    reaction pos/2 - wall-thickness speed/2
	]
	bot: func [ pos speed ][
	    negate reaction size/y - wall-thickness - pos/2 negate speed/2
	]
    ]

    rot-speed: 8

    update: func [ /local  acc ][
	acc: 0
	if key-down? key-map/accelerate [ acc: 0.3 ]
	if key-down? key-map/decellerate [ acc: -0.3 ]
	if key-down? key-map/rot-clockwise [  rot: rot + rot-speed ]
	if key-down? key-map/rot-anticlockwise [ rot: rot - rot-speed ]

	speed/1: speed/1
		+ ( acc * sine rot )
		+ (wall-reactions/left pos speed)
		+ (wall-reactions/right pos speed )
	speed/2: speed/2 
		- ( acc * cosine rot )
		+ (wall-reactions/top pos speed)
		+ (wall-reactions/bot pos speed )

	pos/1: pos/1 + speed/1
	pos/2: pos/2 + speed/2

	speed/1: speed/1 * 0.98
	speed/2: speed/2 * 0.98
	graphic/translate: to-pair pos
	graphic/rotate: rot

	;print [ 'pos pos 'speed speed 'rot rot 'acc acc keys-down mold keys-down ]
    ]

]

astroid: make object! [
    speed: [ 0  0 ]
    pos: size

    graphic: reduce [ 'translate pos 'pen red 'polygon ]

    update: func [ /local  acc ][
	pos/1: pos/1 + speed/1
	pos/2: pos/2 + speed/2
	
	case/all [
	    pos/1 < 0 [ pos/1: pos/1 + size/1 ]
	    pos/2 < 0 [ pos/2: pos/2 + size/2 ]
	    pos/1 > size/1 [ pos/1: pos/1 - size/1 ]
	    pos/2 > size/2 [ pos/2: pos/2 - size/2 ]
	]
	graphic/translate: to-pair pos
    ]

    init: func [ /local alpha r ][
	pos: reduce [ random size/x random size/y ]
	speed:  reduce [ 5 - random 10  5 - random 10 ]
	alpha: 0 
	until [
	    append graphic as-pair 40 + (r: random 20 ) * cosine alpha  40 + r * sine alpha
	    alpha: alpha + 20 + random 50
	    alpha > 360 
	]
    ]
]

astroids: context [
    instances: []
    graphic: []
    init: func [ /local a ][
	loop 20 [
	    append instances a: make astroid [ init ]
	    repend graphic [ 'push a/graphic ]
	]
    ]
    update: func [ /local a ][
	foreach a instances [
	    a/update
	]
    ]  
    init
]

bullets: context [
    one-bullet: [ pen yellow fill-pen off polygon 0x5 3x0 0x-5 -3x0 ]
    speed: 20
    graphic: []
    instances: []

    add-bullet: func [ start-pos vel rot /local velocity ] [
	velocity: reduce [ (speed * sine rot) + vel/1  (negate speed * cosine rot) + vel/2 ]
	repend/only instances  [ copy start-pos copy velocity rot ]
    ]

    update: func [ /local pos velocity rot remove-this ][
	clear graphic
	remove-this: clear []
	foreach bullet instances [
	    set [ pos velocity rot ] bullet
	    either within? to-pair pos 0x0 size [ 
		pos/1: pos/1 + velocity/1
		pos/2: pos/2 + velocity/2
		bullet/1: pos 
		repend graphic  [
		    'push reduce [
			'translate to-pair pos 'rotate rot one-bullet
		    ]
		]
	    ][
		append/only remove-this bullet
	    ]
	]
	foreach x remove-this [  remove find/only instances x ]
    ]
]


key-map: context [ 
    accelerate: #"W"
    decellerate: #"S"
    rot-clockwise: #"D"
    rot-anticlockwise: #"A"
    shoot: #" "
]

context [
    keys-down: make bitset! []
    set 'handle-key-down func [ event ][
	poke keys-down event/key true
    ]
    set 'handle-key-up func [ event ][
	poke keys-down event/key false
    ]

    set 'key-down? func [ key ][  pick keys-down key ]
]


view/no-wait [
    on-key-down [ handle-key-down event ]
    on-key-up [ handle-key-up event ]
    b: box  800x800 #101020
	rate time-step
	on-time [
	    ship/update
	    if key-down? key-map/shoot [
		bullets/add-bullet ship/pos ship/speed ship/rot
	    ]
	    bullets/update
	    astroids/update

	    face/draw/translate: 0x0
	]
	draw reduce [
	    'translate 0x0 
	    'push ship/graphic 
	    'push bullets/graphic
	    'push astroids/graphic
	]

    cl: button "Close" #"^w" [ unview ]
]
