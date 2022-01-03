Red [
	title: Astroids
	author: {Johan Ingvast}
	copyright: {Johan Ingvast 2021}
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

    graphic: reduce [ 'translate pos
	    'fill-pen pink
	    'line-width 3
	    'pen red
	    'polygon
    ]

    pass: 60 

    update: func [  ][
	pos/1: pos/1 + speed/1
	pos/2: pos/2 + speed/2
	
	pos-before: copy pos
	case/all [
	    pos/1 < negate pass [ pos/1: pos/1 + size/1 + pass + pass ]
	    pos/1 - pass > size/1 [ pos/1: pos/1 - size/1 - pass - pass ]

	    pos/2 < negate pass [ pos/2: pos/2 + size/2 + pass + pass ]
	    pos/2 - pass > size/2 [ pos/2: pos/2 - size/2 - pass - pass ]
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
	loop 100 [
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

system/view/auto-sync?: false


view/no-wait [
    on-key-down [ handle-key-down event ]
    on-key-up [ handle-key-up event ]
    game-box: box  800x800 #101020
	;rate time-step
	;on-time [ ]
	draw reduce [
	    'translate 0x0 
	    'push bullets/graphic
	    'push astroids/graphic
	    'push ship/graphic 
	]

    cl: button "Close" #"^w" [ unview ]
]
print "Presented"

screen-update: does [
    ship/update
    if key-down? key-map/shoot [
	bullets/add-bullet ship/pos ship/speed ship/rot
    ]
    bullets/update
    astroids/update
    game-box/draw/translate: 0x0
    show game-box
]

do-events/no-wait

recycle/off

ref-frequency: 20
current-wait: 0.05
last-event-time: now/time/precise

forever [
    screen-update
    do-events/no-wait
    this-time: now/time/precise
    since: this-time - last-event-time
    last-event-time: this-time
    either since < ( 1 / ref-frequency ) [
	wait 1 / ref-frequency - since
    ][
	print [ "Did not make it" since ]
    ]
    recycle
]

