breed [ intersections intersection ]
breed [ pedestrians pedestrian ]
breed [ cars car ]
breed [ tourists tourist ]
breed [ residents resident]
undirected-link-breed [ roads road ]

tourists-own [
  gll
  origin
  moving?
  evacuated?
  speed
  rchd?
  decision
  miltime
]

residents-own [
  gll
  origin
  moving?
  evacuated?
  speed
  rchd?
  decision
  miltime
]

roads-own [
  crowd
  traffic
]

intersections-own [  
   gate?
   gate-type
   temp-id
   previous
   fscore
   gscore
   path
   altpath
   depths
   depth
   speed
   ]

pedestrians-own [
  origin
  prev-origin
  goal
  destination
  moving?
  rd
  evacuated?
  speed
  path
  ev-time
  tr-type
  decision
]

cars-own [
  origin
  prev-origin
  moving?
  rd
  evacuated?
  destination
  goal
  acc
  speed
  path
  ev-time
  tr-type
  decision
]

globals [ 
  ev-times
  xts
  yts
  trnum
  xrs
  yrs
  rsnum
]

to load-network [ filename ]
  clear-all  
  if (filename = false)
    [ stop ]
  file-open filename
  let num-intersections file-read
  let num-links file-read
  let ideal-segment-length file-read

  let id-counter 0  
  repeat num-intersections
  [ 
    create-intersections 1 [
      set temp-id id-counter
      set id-counter id-counter + 1
      set xcor file-read
      set ycor file-read
      set gate? false
      set size 0.1
      set shape "square"
      set color white
      set depths -1
    ]
  ]
  repeat num-links
  [
    let id1 file-read
    let id2 file-read
    let primary? file-read
    
    ask intersections with [ temp-id = id1 ]
    [ 
        create-roads-with intersections with [ temp-id = id2 ]
    ]
  ]
  ask roads [
    set color white
    set thickness 0.05
  ]
  
  file-close
  output-print "Network Loaded"
  beep
end

to load-routes
  load-routes-file "SeasideRoutesExstPlan"
  load-routes-file "SeasideRoutesAltPlan"
  beep
  output-print "Routes Loaded"
end


to load-routes-file [file-name]
  if (file-name = false) [ stop ]
  file-open file-name
  let mode file-read
  
  if mode = -1 [
    let cnt file-read
    repeat cnt [
      let num file-read
      ask intersection num [
        set altpath file-read
      ]
    ]
  ]
  if mode = 0 [
    let cnt file-read
    repeat cnt [
      let num file-read
      ask intersection num [
        set path file-read
      ]
    ]
  ]
  file-close
end


to save-route [ filename ]
  carefully [ file-delete filename ] [ ]
  if (filename = false)
    [ stop ]
  let id 1
  file-open filename
  file-write count intersections
  ask intersections [
    show id
    file-write who
    file-write Astar self (nearestGoal self)
    set id id + 1
  ]
  file-close
end

to load-gates
   ask intersections [
    set gate? false
    set color white
    set size 0.1
  ]
  ifelse Alternative-Plan-Mode [ 
    load-gates-file "SeasideGatesHor"
    load-gates-file "SeasideGatesVer"
  ]
  [
    load-gates-file "SeasideGatesHor"
  ]
  output-print "Gates Loaded"
  beep
end

to load-gates-file [ filename ]
  if (filename = false)
    [ stop ]
  file-open filename
  let mode file-read
  let num file-read
  repeat num [
    ask intersection file-read [
       st
       set gate? true
       if mode = 0 [set gate-type "Hor"]
       if mode = -1 [set gate-type "Ver"]
    ]
  ]
  file-close
  beep
end

to show-gates
  ask intersections with [gate? = true and gate-type = "Hor"]
  [
    set shape "circle"
    set size 1
    set color yellow
  ]
  ask intersections with [gate? = true and gate-type = "Ver"]
  [
    set shape "circle"
    set size 1
    set color violet
  ]
end


to load-Tsunami [file-name]
  if (file-name = false) [ stop ]
  file-open file-name
  while [ not file-at-end? ]
  [
    let xd file-read
    let yd file-read
    set xd ( xd + 123.924793 ) * 524.6968613
    set yd ( yd - 45.993087 ) * 524.6968613
    let dps [0]
    repeat 90 [
      set dps lput file-read dps
    ]
    ask intersections with-min [ distancexy xd yd ][
        set depths dps
    ]
  ]
  file-close
  output-print "TsunamiData Loaded"
  beep
end


to read-tourists [ filename ]
  file-close-all
  if (filename = false)
    [ stop ]
  set xts []
  set yts []
  file-open filename
  set trnum file-read
  repeat trnum [
    set xts lput file-read xts
    set yts lput file-read yts
  ]
  file-close
  beep
end

to read-residents [ filename ]
  file-close-all
  if (filename = false)
    [ stop ]
  set xrs []
  set yrs []
  file-open filename
  set rsnum file-read
  repeat rsnum [
    set xrs lput file-read xrs
    set yrs lput file-read yrs
  ]
  file-close
  beep
end

to setup-tourists
  
  ask tourists [ die ]
  ask intersections [ ht ]
  let xt xts
  let yt yts
  repeat trnum [
    create-tourists 1 [
      set xcor item 0 xt
      set ycor item 0 yt
      set xt remove-item 0 xt
      set yt remove-item 0 yt
      set color yellow
      set shape "dot"
      set size 0.5
      set moving? true
      set gll min-one-of intersections [ distance myself ]
      set speed random-normal Ped-Speed Ped-Sigma
      set speed speed * 0.00574
      if speed < 0.001 [set speed 0.001]
      
      set evacuated? false
      set rchd? false
      let rnd random 100
      if (rnd >= 0 and rnd < T0-NoAction ) [
        set decision 0
      ]
      if (rnd >= T0-NoAction and rnd < T0-NoAction + T1-HorEvac-Foot ) [
        set decision 1
        set miltime ((Rayleigh-random Tsig1) + Ttau1 ) * 60 
      ]
      if (rnd >= T0-NoAction + T1-HorEvac-Foot and rnd < T0-NoAction + T1-HorEvac-Foot + T2-HorEvac-Car ) [
        set decision 2
        set miltime ((Rayleigh-random Tsig2) + Ttau2 ) * 60
      ]
      if (rnd >= T0-NoAction + T1-HorEvac-Foot + T2-HorEvac-Car and rnd < T0-NoAction + T1-HorEvac-Foot + T2-HorEvac-Car + T3-VerEvac-Foot ) [
        set decision 3
        set miltime ((Rayleigh-random Tsig3) + Ttau3 ) * 60
      ]
      
      if immediate-evacuation [
        set miltime 0
      ]
      
      st
    ]
  ]
end


to setup-residents
  
  ask residents [ die ]
  ask intersections [ ht ]
  let xr xrs
  let yr yrs
  
  repeat rsnum [
    create-residents 1 [
      set xcor item 0 xr
      set ycor item 0 yr
      set xr remove-item 0 xr
      set yr remove-item 0 yr
      set color brown
      set shape "dot"
      set size 0.5
      set moving? true
      set gll min-one-of intersections [ distance myself ]
      set speed random-normal Ped-Speed Ped-Sigma
      set speed speed * 0.00574
      if speed < 0.001 [set speed 0.001]
      
      set evacuated? false
      set rchd? false
      let rnd random 100
      if (rnd >= 0 and rnd < R0-NoAction ) [
        set decision 0
      ]
      if (rnd >= R0-NoAction and rnd < R0-NoAction + R1-HorEvac-Foot ) [
        set decision 1
        set miltime ((Rayleigh-random Rsig1) + Rtau1 ) * 60
      ]
      if (rnd >= R0-NoAction + R1-HorEvac-Foot and rnd < R0-NoAction + R1-HorEvac-Foot + R2-HorEvac-Car ) [
        set decision 2
        set miltime ((Rayleigh-random Rsig2) + Rtau2 ) * 60
      ]
      if (rnd >= R0-NoAction + R1-HorEvac-Foot + R2-HorEvac-Car and rnd < R0-NoAction + R1-HorEvac-Foot + R2-HorEvac-Car + R3-VerEvac-Foot ) [
        set decision 3
        set miltime ((Rayleigh-random Rsig3) + Rtau3 ) * 60
      ]
      
      if immediate-evacuation [
        set miltime 0
      ]
      
      st
    ]
  ]
  beep
end

to setup-init-val
  
  set T0-NoAction 20
  ifelse Alternative-Plan-Mode [
    set T1-HorEvac-Foot 40
    set T2-HorEvac-Car 20
    set T3-VerEvac-Foot 20
  ]
  [
    set T1-HorEvac-Foot 60
    set T2-HorEvac-Car 20
    set T3-VerEvac-Foot 0
  ]
  
  set R0-NoAction 10
  ifelse Alternative-Plan-Mode [
    set R1-HorEvac-Foot 50
    set R2-HorEvac-Car 30
    set R3-VerEvac-Foot 10
  ]
  [
    set R1-HorEvac-Foot 60
    set R2-HorEvac-Car 30
    set R3-VerEvac-Foot 0
  ]

  set Hc 0.5
  
  set immediate-evacuation False
  
  set Ped-Speed 1.22
  set Ped-Sigma 0.2
  
  set Max-Speed 11.2
  set acceleration 1.41
  set deceleration 7.14
  
  set Rtau1 1
  set Rsig1 0.5
  set Rtau2 1
  set Rsig2 0.5
  set Rtau3 1
  set Rsig3 0.5
  
  set Ttau1 1
  set Tsig1 0.5
  set Ttau2 1
  set Tsig2 0.5
  set Ttau3 1
  set Tsig3 0.5

end


to load-population
  setup-tourists
  setup-residents
  output-print "Population Loaded"
  beep
end

to read-all
  ca
  ask tourists [die]
  ask residents [die]
  ask pedestrians [die]
  ask cars [die]
  set ev-times []
  load-network "SeasideFinalMap"
  load-Tsunami "SeasideTsunamiData"
  load-routes
  read-tourists "TouristsXY"
  read-residents "ResidentsXY"
  load-population
  load-gates
  show-gates
  ask roads [
    set traffic 0
    set crowd 0
  ]

  reset-ticks
end

to reset
  clear-all-plots
  clear-output
  set ev-times []
  ask roads
  [
    set traffic 0
    set crowd 0
  ]
  ask tourists [die]
  ask residents [die]
  ask pedestrians [die]
  ask cars [die]
  read-tourists "TouristsXY"
  read-residents "ResidentsXY"
  load-population
  load-gates
  show-gates
  clear-output
  output-print "Reset Done"
  beep
  reset-ticks
end




to-report speedfunc [ c spd]
   ask c [
     let car-ahead cars-on patch-ahead 1 
     set car-ahead one-of car-ahead with [ abs ( heading - ( [ heading ] of c ) ) < 20 and moving? = true ]
     ifelse car-ahead != nobody
     [
       set spd [speed] of car-ahead
       set spd ( spd - ( deceleration * 0.00574 ) )
     ]
      ;; otherwise, speed up
     [
       set spd ( spd + ( acceleration * 0.00574 ) )
     ]     
     ;;; don't slow down below speed minimum or speed up beyond speed limit
     ; 1 tick = 1 sec
     ; 1 patch = 174.4 m
     ; fd 0.2 = 34.88 m/s = 125.56 km/h
     ; 0.008 = 5 km/h , 0.127 = 80 km/h , 0.077 = 48 km/h = 35 mph
     
     if spd < 0.008 [ set spd 0.008 ]
     if spd > ( Max-speed * 0.00574 ) [ set spd ( Max-speed * 0.00574 ) ]
   ]
   report spd
end


to-report rayleigh-random [sigma]
  report (sqrt( ( - ln ( 1 - random-float 1 )) * ( 2 * ( sigma ^ 2 ))))
end


to-report Astar-smallest [ q ]
  let rep 0
  let fsc 100000000
  foreach q [
    let fscr [fscore] of intersection ?
    if fscr < fsc [
      set fsc fscr
      set rep ?
    ]
  ]
  report rep
end

;;huristic-cost-estimate:
to-report hce [ source gl ]
  let euclidian 100000
  ask source [
    set euclidian distance gl
  ]
  report euclidian
end

to-report nearestGoal [ source ]
  let goals intersections with [gate?]
  report min-one-of goals [ distance source]
end

to-report Astar [ source gl ]
  let reached? false
  let dstn nobody
  let closedset []
  let openset []
  
  ask intersections [
    set previous -1
  ]
    
  set openset lput [who] of source openset
  ask source [
    set gscore 0
    set fscore (gscore + hce source gl)
  ]
  while [ not empty? openset and (not reached?)] [
    let current Astar-smallest openset
    ;;show current
    if current = [who] of gl or [gate?] of intersection current = True [
      ;reconstruct path
      set dstn intersection current
      set reached? true
      
    ]
    set openset remove current openset
    set closedset lput current closedset
    ask intersection current [
      let neighbs link-neighbors
      ask neighbs [
        let tent-gscore [gscore] of myself + [link-length] of (road who [who] of myself)
        let tent-fscore tent-gscore + hce self gl
        if ( member? who closedset and ( tent-fscore >= fscore ) ) [stop];[ continue ]
        if ( not member? who closedset or ( tent-fscore >= fscore )) [
          set previous current
          set gscore tent-gscore
          set fscore tent-fscore
          if not member? who openset [
            set openset lput who openset
          ]
        ]
      ]
    ]
  ]
  
  let route []
  while [ [previous] of dstn != -1 ] [
    set route fput [who] of dstn route
    set dstn intersection ([previous] of dstn)
  ]
  ask source [
    set path route
  ]
  report route      
end


to check
  let q [1037]
  while [ not empty? q ] [
     let a first q
     ask intersection a [
       set color red
     ]
     set q remove a q
     ask intersection a [
     ask road-neighbors [
       if color != red [
         set q lput who q
       ]
     ]
     ]
  ]
end


to go
  
  if ticks >= 5220 [
    ask cars with [color != red][
      set color green
    ]
    ask pedestrians with [color != red][
      set color green
    ]
    ask tourists with [color != red][
      set color green
    ]
    ask residents with [color != red][
      set color green
    ]
    output-print "END OF THE MODEL"
    output-print "Minutes Passed:"
    output-print (ticks / 60)
    output-print "Number of Survived:"
    output-print (count turtles with [color = green])
    output-print "Number of Died:"
    output-print (count turtles with [color = red])
    Let N_000 ( count residents with [color = green and decision = 0 ] + count cars with [ color = green and decision = 0 and tr-type = "rs" ] + count pedestrians with [color = green and decision = 0 and tr-type = "rs" ])
    Let N_001 ( count residents with [color = red and decision = 0 ] + count cars with [color = red and decision = 0 and tr-type = "rs" ] + count pedestrians with [color = red and decision = 0 and tr-type = "rs" ])
    Let N_010 ( count residents with [color = green and decision = 1 ] + count cars with [color = green and decision = 1 and tr-type = "rs" ] + count pedestrians with [color = green and decision = 1 and tr-type = "rs" ])
    Let N_011 ( count residents with [color = red and decision = 1 ] + count cars with [color = red and decision = 1 and tr-type = "rs" ] + count pedestrians with [color = red and decision = 1 and tr-type = "rs" ])
    Let N_020 ( count residents with [color = green and decision = 2 ] + count cars with [color = green and decision = 2 and tr-type = "rs" ] + count pedestrians with [color = green and decision = 2 and tr-type = "rs" ])
    Let N_021 ( count residents with [color = red and decision = 2 ] + count cars with [color = red and decision = 2 and tr-type = "rs" ] + count pedestrians with [color = red and decision = 2 and tr-type = "rs" ])
    Let N_030 ( count residents with [color = green and decision = 3 ] + count cars with [color = green and decision = 3 and tr-type = "rs" ] + count pedestrians with [color = green and decision = 3 and tr-type = "rs" ])
    Let N_031 ( count residents with [color = red and decision = 3 ] + count cars with [color = red and decision = 3 and tr-type = "rs" ] + count pedestrians with [color = red and decision = 3 and tr-type = "rs" ])
    
    Let N_100 ( count tourists with [color = green and decision = 0 ] + count cars with [color = green and decision = 0 and tr-type = "tr" ] + count pedestrians with [color = green and decision = 0 and tr-type = "tr" ])
    Let N_101 ( count tourists with [color = red and decision = 0 ] + count cars with [color = red and decision = 0 and tr-type = "tr" ] + count pedestrians with [color = red and decision = 0 and tr-type = "tr" ])
    Let N_110 ( count tourists with [color = green and decision = 1 ] + count cars with [color = green and decision = 1 and tr-type = "tr" ] + count pedestrians with [color = green and decision = 1 and tr-type = "tr" ])
    Let N_111 ( count tourists with [color = red and decision = 1 ] + count cars with [color = red and decision = 1 and tr-type = "tr" ] + count pedestrians with [color = red and decision = 1 and tr-type = "tr" ])
    Let N_120 ( count tourists with [color = green and decision = 2 ] + count cars with [color = green and decision = 2 and tr-type = "tr" ] + count pedestrians with [color = green and decision = 2 and tr-type = "tr" ])
    Let N_121 ( count tourists with [color = red and decision = 2 ] + count cars with [color = red and decision = 2 and tr-type = "tr" ] + count pedestrians with [color = red and decision = 2 and tr-type = "tr" ])
    Let N_130 ( count tourists with [color = green and decision = 3 ] + count cars with [color = green and decision = 3 and tr-type = "tr" ] + count pedestrians with [color = green and decision = 3 and tr-type = "tr" ])
    Let N_131 ( count tourists with [color = red and decision = 3 ] + count cars with [color = red and decision = 3 and tr-type = "tr" ] + count pedestrians with [color = red and decision = 3 and tr-type = "tr" ])
    
    ;print "N_000"
    ;print N_000
    ;print "N_001"
    ;print N_001
    ;print "N_010"
    ;print N_010
    ;print "N_011"
    ;print N_011
    ;print "N_020"
    ;print N_020
    ;print "N_021"
    ;print N_021
    ;print "N_030"
    ;print N_030
    ;print "N_031"
    ;print N_031
    
    ;print "N_100"
    ;print N_100
    ;print "N_101"
    ;print N_101
    ;print "N_110"
    ;print N_110
    ;print "N_111"
    ;print N_111
    ;print "N_120"
    ;print N_120
    ;print "N_121"
    ;print N_121
    ;print "N_130"
    ;print N_130
    ;print "N_131"
    ;print N_131
    
    tick
    
    if save-output-to-file [
    file-open user-new-file
    
    file-print "INPUTS"
    
    file-write "alternative_plan"
    file-write alternative-plan-mode
    file-print ""
    
    file-write "tourist_decision_0"
    file-write T0-NoAction
    file-print ""
    file-write "tourist_decision_1"
    file-write T1-HorEvac-Foot
    file-print ""
    file-write "tourist_decision_2"
    file-write T2-HorEvac-Car
    file-print ""
    file-write "tourist_decision_3"
    file-write T3-VerEvac-Foot
    file-print ""
    
    file-write "resident_decision_0"
    file-write R0-NoAction
    file-print ""
    file-write "resident_decision_1"
    file-write R1-HorEvac-Foot
    file-print ""
    file-write "resident_decision_2"
    file-write R2-HorEvac-Car
    file-print ""
    file-write "resident_decision_3"
    file-write R3-VerEvac-Foot
    file-print ""
    
    file-write "crit-depth"
    file-write Hc
    file-print ""
    
    file-write "foot_speed"
    file-write Ped-Speed
    file-print ""
    
    file-write "foot_std"
    file-write Ped-Sigma
    file-print ""
    
    file-write "car_max_speed"
    file-write Max-Speed
    file-print ""
    
    file-write "car_accel"
    file-write acceleration
    file-print ""
    
    file-write "car_decel"
    file-write deceleration
    file-print ""
    
    file-write "immdediate-evac"
    file-write immediate-evacuation
    file-print ""
    
    file-write "Rtau1"
    file-write Rtau1
    file-print ""
    file-write "Rsig1"
    file-write Rsig1
    file-print ""
    file-write "Rtau2"
    file-write Rtau2
    file-print ""
    file-write "Rsig2"
    file-write Rsig2
    file-print ""
    file-write "Rtau3"
    file-write Rtau3
    file-print ""
    file-write "Rsig3"
    file-write Rsig3
    file-print ""
    file-write "Ttau1"
    file-write Ttau1
    file-print ""
    file-write "Tsig1"
    file-write Tsig1
    file-print ""
    file-write "Ttau2"
    file-write Ttau2
    file-print ""
    file-write "Tsig2"
    file-write Tsig2
    file-print ""
    file-write "Ttau3"
    file-write Ttau3
    file-print ""
    file-write "Tsig3"
    file-write Tsig3
    file-print ""
    
    file-print "OUTPUTS"
    
    file-write "N_000"
    file-write N_000
    file-print ""
    file-write "N_001"
    file-write N_001
    file-print ""
    file-write "N_010"
    file-write N_010
    file-print ""
    file-write "N_011"
    file-write N_011
    file-print ""
    file-write "N_020"
    file-write N_020
    file-print ""
    file-write "N_021"
    file-write N_021
    file-print ""
    file-write "N_030"
    file-write N_030
    file-print ""
    file-write "N_031"
    file-write N_031
    file-print ""
    
    file-write "N_100"
    file-write N_100
    file-print ""
    file-write "N_101"
    file-write N_101
    file-print ""
    file-write "N_110"
    file-write N_110
    file-print ""
    file-write "N_111"
    file-write N_111
    file-print ""
    file-write "N_120"
    file-write N_120
    file-print ""
    file-write "N_121"
    file-write N_121
    file-print ""
    file-write "N_130"
    file-write N_130
    file-print ""
    file-write "N_131"
    file-write N_131
    file-print ""
    
    file-close
    ]
    stop
  ]
  
  if ticks mod 58 = 0 [
    ask intersections [
      set depth item int(ticks / 58) depths
    ]
  ]
  
  ask tourists with [(moving? = true) and (decision != 0) and (miltime <= ticks)]
  [
    set heading towards gll
    fd speed
    if (distance gll < (speed) )
    [
      set moving? false
      set rchd? true
      set origin gll
      if [gate?] of origin
      [
        set color green
        set moving? 0
        set evacuated? true
        ;set ev-times lput ( ticks / 60 ) ev-times
      ]
      if [depth] of origin >= Hc and evacuated? = false [
        set color red
        set moving? 0
        set evacuated? true
      ]
    ]
  ]
  
  ask residents with [(moving? = true) and (decision != 0) and (miltime <= ticks)]
  [
    set heading towards gll
    fd speed
    if (distance gll < (speed) )
    [
      set moving? false
      set rchd? true
      set origin gll
      if [gate?] of origin
      [
        set color green
        set moving? 0
        set evacuated? true
        ;set ev-times lput ( ticks / 60 ) ev-times
      ]
      if [depth] of origin >= Hc and evacuated? = false [
        set color red
        set moving? 0
        set evacuated? true
      ]
    ]
  ]
  
  ask tourists with [ rchd? = false and evacuated? = false]
  [
    if [depth] of gll > Hc[
      set color red
      set moving? 0
      set evacuated? true
    ]
  ]
  
  ask residents with [ rchd? = false and evacuated? = false]
  [
    if [depth] of gll > Hc [
      set color red
      set moving? 0
      set evacuated? true
    ]
  ]
  
  ask tourists with [ rchd? = true ]
  [
    if decision = 1 [
      ; horizontal evacuation - by foot
      ask origin [
        set speed [speed] of myself
        hatch-pedestrians 1 [
          set color orange
          set size 0.5
          set shape "dot"
          set origin myself
          set speed [speed] of myself
          set path [path] of myself
          set prev-origin origin
          set evacuated? false
          set moving? false
          ifelse empty? path [
            set goal -1
          ]
          [
            set goal last path
          ]
          set tr-type "tr"
          set decision 1
          st
        ]
      ]
    ]
    
    
    if decision = 2 [
      ; horizontal evacuation - by car
      ask origin [
        hatch-cars 1 [
          set color orange
          set size 0.5
          set shape "default"
          set origin myself
          set path [path] of myself
          set prev-origin origin
          set evacuated? false
          set moving? false
          ifelse empty? path[
            set goal -1
          ]
          [
            set goal last path
          ]
          set tr-type "tr"
          set decision 2
          st
        ]
      ]
    ]
    
    
    if decision = 3 [
      ; vertical evacuation - by foot
      ask origin [
        set speed [speed] of myself
        hatch-pedestrians 1 [
          set color orange
          set size 0.5
          set shape "dot"
          set origin myself
          set speed [speed] of myself
          ifelse (([ycor] of myself) - (3.4913 * ([xcor] of myself)) + 1.3056) < 0 [
            set path [path] of myself
          ]
          [
            set path [altpath] of myself
          ]
          set prev-origin origin
          set evacuated? false
          set moving? false
          ifelse empty? path [
            set goal -1
          ]
          [
            set goal last path
          ]
          set tr-type "tr"
          set decision 3
          st
        ]
      ]
    ]
    die
  ]
  
  ask residents with [ rchd? = true ]
  [
    if decision = 1 [
      ; horizontal evacuation - by foot
      ask origin [
        set speed [speed] of myself
        hatch-pedestrians 1 [
          set color sky
          set size 0.5
          set shape "dot"
          set origin myself
          set speed [speed] of myself
          set path [path] of myself
          set prev-origin origin
          set evacuated? false
          set moving? false
          ifelse empty? path [
            set goal -1
          ]
          [
            set goal last path
          ]
          set tr-type "rs"
          set decision 1
          st
        ]
      ]
    ]
    
    
    if decision = 2 [
      ; horizontal evacuation - by car
      ask origin [
        hatch-cars 1 [
          set color sky
          set size 0.5
          set shape "default"
          set origin myself
          set path [path] of myself
          set prev-origin origin
          set evacuated? false
          set moving? false
          ifelse empty? path [
            set goal -1
          ]
          [
            set goal last path
          ]
          set tr-type "rs"
          set decision 2
          st
        ]
      ]
    ]
    
    
    if decision = 3 [
      ; vertical evacuation - by foot
      ask origin [
        set speed [speed] of myself
        hatch-pedestrians 1 [
          set color sky
          set size 0.5
          set shape "dot"
          set origin myself
          set speed [speed] of myself
          ifelse (([ycor] of myself) - (3.4913 * ([xcor] of myself)) + 1.3056) < 0 [
            set path [path] of myself
          ]
          [
            set path [altpath] of myself
          ]
          set prev-origin origin
          set evacuated? false
          set moving? false
          ifelse empty? path [
            set goal -1
          ]
          [
            set goal last path
          ]
          set tr-type "rs"
          set decision 3
          st
        ]
      ]
    ]
  die
  ]
  
  
  
  ;;Cars:
  ask cars
  [
   if [who] of origin = goal or goal = -1
      [
        set color green
        set moving? 0
        set evacuated? true
        ;set ev-times lput ( ticks / 60 ) ev-times
      ]
   if [depth] of origin >= Hc and evacuated? = false [
        set color red
        set moving? 0
        set evacuated? true
    ]
  ]
  ask cars with [ ( moving? = false)]
  [  
    let dest item 0 path
    set path remove dest path
    set destination intersection dest
    set heading towards destination
    set moving? true
    set rd road ([who] of destination) ([who] of origin)
    ask rd
    [
      set traffic traffic + 1
    ]
  ]
  
  ask cars with [moving? = true]
  [
    set speed speedfunc self speed
    fd speed
    if (distance destination < (speed) )
    [
      set moving? false
      ask rd [ set traffic traffic - 1]
      set prev-origin origin
      set origin destination
      if [who] of origin = goal or goal = -1
      [
        set color green
        set moving? 0
        set evacuated? true
        ;set ev-times lput ( ticks / 60 ) ev-times
      ]
      if [depth] of origin >= Hc and evacuated? = false [
        set color red
        set moving? 0
        set evacuated? true
      ]
    ]
  ]
  
  ;;Pedestrians:
  ask pedestrians
  [
   if [who] of origin = goal or goal = -1
      [
        set color green
        set moving? 0
        set evacuated? true
        ;set ev-times lput ( ticks / 60 ) ev-times
      ]
    if [depth] of origin >= Hc and evacuated? = false [
        set color red
        set moving? 0
        set evacuated? true
    ]
  ]
  ask pedestrians with [ ( moving? = false) ]
  [
    let dest item 0 path
    set path remove dest path
    set destination intersection dest
    set heading towards destination
    set moving? true
    set rd road ([who] of destination) ([who] of origin)
    ask rd
    [
      set crowd crowd + 1
    ]
  ]
  ask pedestrians with [moving? = true]
  [
    fd speed
    if (distance destination < (speed) )
    [
      set moving? false
      set prev-origin origin
      set origin destination
      if [who] of origin = goal or goal = -1
      [
        set color green
        set moving? 0
        set evacuated? true
        ;set ev-times lput ( ticks / 60 ) ev-times
      ]
      if [depth] of origin >= Hc and evacuated? = false [
        set color red
        set moving? 0
        set evacuated? true
      ]
    ]
  ]
  if ticks mod 600 = 0
  [
    output-print "Minutes Passed:"
    output-print (ticks / 60)
    output-print "Number of Survived:"
    output-print (count cars with [color = green] + count pedestrians with [color = green])
    output-print "Number of Died:"
    output-print (count turtles with [color = red])

    output-print "--------------"
    
  ]
  tick
end

to XYs [filename]
  carefully [ file-delete filename ] [ ]
  if (filename = false)
    [ stop ]
  file-open filename
  let id 1
  ask intersections [
    show id
    set id id + 1
    file-write -123.924793 + (xcor / 524.6968613)
    file-write 45.993087 + (ycor / 524.6968613)
    file-print ""
  ]
  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
230
10
950
751
17
17
20.3
1
10
1
1
1
0
0
0
1
-17
17
-17
17
1
1
1
ticks
30.0

PLOT
961
203
1307
347
Number of Evacuated
Min
#
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Total" 1.0 0 -10899396 true "" "plotxy (ticks / 60) (count cars with [color = green] + count pedestrians with [color = green])"
"Tourists" 1.0 0 -955883 true "" "Plotxy (ticks / 60) count pedestrians with [color = green and tr-type = \"tr\"] + count cars with [color = green and tr-type = \"tr\"]"
"Residents" 1.0 0 -13791810 true "" "Plotxy (ticks / 60) count pedestrians with [color = green and tr-type = \"rs\"] + count cars with [color = green and tr-type = \"rs\"]"
"Pedestrians" 1.0 0 -7500403 true "" "plotxy (ticks / 60) count pedestrians with [color = green]"
"Cars" 1.0 0 -2674135 true "" "plotxy (ticks / 60)count cars with [color = green]"

SWITCH
7
46
220
79
immediate-evacuation
immediate-evacuation
1
1
-1000

BUTTON
1154
10
1292
43
GO
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
7
10
220
43
Alternative-Plan-Mode
Alternative-Plan-Mode
1
1
-1000

TEXTBOX
9
116
205
144
Tourists' Decision Making Probabalities : (Percent)
11
0.0
1

INPUTBOX
8
146
97
206
T0-NoAction
20
1
0
Number

INPUTBOX
111
147
211
207
T1-HorEvac-Foot
60
1
0
Number

INPUTBOX
111
213
211
273
T2-HorEvac-Car
20
1
0
Number

INPUTBOX
8
212
96
272
T3-VerEvac-Foot
0
1
0
Number

TEXTBOX
10
271
219
299
Residents' Decision Making Probabalisties : (Percent)
11
0.0
1

INPUTBOX
7
301
93
361
R0-NoAction
10
1
0
Number

INPUTBOX
108
300
209
360
R1-HorEvac-Foot
60
1
0
Number

INPUTBOX
7
367
93
427
R3-VerEvac-Foot
0
1
0
Number

INPUTBOX
107
368
208
428
R2-HorEvac-Car
30
1
0
Number

TEXTBOX
965
53
1115
71
Output Box:
11
0.0
1

MONITOR
965
74
1047
119
Time (min)
ticks / 60
1
1
11

INPUTBOX
137
434
208
494
Hc
0.5
1
0
Number

PLOT
962
355
1308
475
Number of Casualties
Min
#
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Dead" 1.0 0 -2674135 true "" "plotxy (ticks / 60) (count turtles with [color = red])"

BUTTON
1026
10
1081
43
READ
read-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1088
10
1146
43
RESET
reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
964
10
1019
43
Initialize
setup-init-val
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
16
439
132
457
Critical Depth: (Meters)
11
0.0
1

INPUTBOX
6
729
56
789
Rtau1
1
1
0
Number

INPUTBOX
56
729
106
789
Rsig1
0.5
1
0
Number

INPUTBOX
126
729
176
789
Ttau1
1
1
0
Number

INPUTBOX
175
729
225
789
Tsig1
0.5
1
0
Number

INPUTBOX
6
791
56
851
Rtau2
1
1
0
Number

INPUTBOX
55
791
105
851
Rsig2
0.5
1
0
Number

INPUTBOX
125
791
175
851
Ttau2
1
1
0
Number

INPUTBOX
175
791
225
851
Tsig2
0.5
1
0
Number

INPUTBOX
7
852
57
912
Rtau3
1
1
0
Number

INPUTBOX
56
852
106
912
Rsig3
0.5
1
0
Number

INPUTBOX
125
853
175
913
Ttau3
1
1
0
Number

INPUTBOX
175
853
225
913
Tsig3
0.5
1
0
Number

TEXTBOX
7
696
196
724
Evacuation Decsion Making Times:
11
0.0
1

TEXTBOX
34
712
84
730
Residents
11
0.0
1

TEXTBOX
159
712
199
730
Tourists
11
0.0
1

SWITCH
7
83
220
116
Save-Output-To-File
Save-Output-To-File
1
1
-1000

TEXTBOX
11
497
60
525
On foot: (m/s)
11
0.0
1

INPUTBOX
60
499
130
559
Ped-Speed
1.22
1
0
Number

INPUTBOX
137
499
208
559
Ped-Sigma
0.2
1
0
Number

TEXTBOX
11
563
55
596
By Car: (m/s)
11
0.0
1

INPUTBOX
60
562
208
622
Max-Speed
11.2
1
0
Number

INPUTBOX
60
624
133
684
Acceleration
1.41
1
0
Number

INPUTBOX
135
624
208
684
Deceleration
7.14
1
0
Number

TEXTBOX
14
656
57
684
(m/s^2)
11
0.0
1

MONITOR
1056
74
1133
119
Not Moving
count residents with [ miltime >= ticks or decision = 0 ] + count tourists with [ miltime >= ticks or decision = 0 ]
17
1
11

MONITOR
1143
73
1219
118
En Route
count residents + count tourists + count pedestrians + count cars - count residents with [ miltime >= ticks or decision = 0 ] - count tourists with [ miltime >= ticks or decision = 0 ] - count turtles with [color = green] - count turtles with [color = red] + count residents with [ (miltime >= ticks or decision = 0) and ( color = red or color = green )] + count tourists with [(miltime >= ticks or decision = 0) and ( color = red or color = green)]
17
1
11

MONITOR
965
126
1047
171
Evacuated
count turtles with [ color = green ]
17
1
11

MONITOR
1056
126
1133
171
Casualty
count turtles with [ color = red ]
17
1
11

MONITOR
1143
126
1218
171
Mortality (%)
count turtles with [color = red] / (count residents + count tourists + count pedestrians + count cars) * 100
2
1
11

@#$#@#$#@
## WHAT IS IT?

This model is a flexible design tool for creating road networks that may be imported into the CITIES model, which simulates urban growth and land usage patterns.  The CITIES model is capable of growing its own sophisticated road networks, in a rather organic fashion, by having road-builder agents wander the map and create roads where it would be logical to do so.  However, sometimes it is desirable to have more fine-grained control over the road network structure within a city, and this Road Network Builder model serves this purpose.

## HOW IT WORKS

A road network is defined by some number of road "intersections", which have physical locations in the world.  These intersection nodes may be connected to other interseciton nodes by roads, which are straight line segments between nodes.  Note, however, that a curvy section of road may be simulated by stringing together several intersection nodes that each have only two roads going out of them.  The intersection nodes can be repositioned either by using automated tools (such as the PERTURB or STRAIGHTEN buttons), or by manually adjusting single nodes using mouse interaction.  

Road segments may be designated either primary or tertiary.  Primary roads appear thicker in the visual display, and colored sky blue, rather than gray.

The networks that are created can be saved, and re-loaded for further editing at a future date.  The saved road networks can also be imported into the CITIES model.

## HOW TO USE IT

There are two basic setup patterns for the road network included in this model (though it could be extended to have others).  These are a grid pattern (initiated by the SETUP-GRID button) and a radial hub pattern (initiated by the SETUP-RADIAL button).  The size of the road network is controlled by the ROAD-NETWORK-SIZE slider.  In both patterns, initially all roads are marked as tertiary.  If you wish to have primary roads, you must manually mark them using mouse interaction.

There are several functions that work on the network as a whole.

The PERTURB button causes all of the intersections to jitter randomly.  

The STRAIGHTEN button causes all of the intersections to move back toward their original locations.  Some important notes:  1) when nodes are moved manually, the locations they were moved to is considered to be their "original location" 2) when a road network is loaded from a file, the loaded locations are considered to be the original locations.

The SPARSIFY button removes roads randomly from the network, resulting in a more sparse road network.  SPARSIFY will never remove a road that would cause an intersection to become a dead-end -- if you want to do this, you must manually do it with the USE-MOUSE mode.  Also, SPARSIFY will never remove road segments that are marked as primary.

Conversely, the DENSIFY button randomly adds more roads to the road network.  Roads are only added in ways that do not create underpasses/overpasses (i.e. line edge intersections) with existing roads.

The SPREAD button uses a visual graph layout algorithm called "spring layout" that pushes and pulls the intersection nodes as if there were coiled springs in place of the road edges.  Also, all nodes repel all other nodes, to keep them from getting too close to each other.  This often results in smooth and rather pleasing road network formations.  A single click of this button moves the nodes a little bit in the direction of the forces acting on them.

To manually interact with individual roads and intersections, click down the USE-MOUSE button to turn on mouse interaction.  Note that several of the buttons that you can use to interact with the network (DELETE-INTERSECTION, CREATE-INTERSECTION, REMOVE-ROAD, ADD-ROAD, MAKE-PATH-PRIMARY, MAKE-PATH-TERTIARY) have keyboard shortcut keys that you can use (shown in the 

When USE-MOUSE is turned on, you can click and drag intersection nodes to new locations.  If DRAG-NEIGHBORS-TOO? switch is turned ON, then the nodes that are connected to the node being dragged are also repositioned.

The most recently selected node is colored red, and the second most recently selected node is colored pink.

The DELETE-INTERSECTION button will remove the most recently selected node (the red node), as well as any road segments that connect to it.

The CREATE-INTERSECTION button will create a new intersection node (with no road segments attached to it) somewhere in the world view.  If the mouse cursor is currently positioned inside the world view (which is possible, if you are using the shortcut keys), the new node will appear at the current mouse location.  Otherwise, the location of the new node on the map is somewhat unpredictable.  The new node will beceom the "most recently selected" node, and will be colored red.

The REMOVE-ROAD button removes the road segment (if one exists) between the two most recently selected intersection nodes (the red and pink nodes).

The ADD-ROAD button adds a road segment between the two most recently selected intersection nodes, if one does not already exist.

The MAKE-PATH-PRIMARY button selects a (shortest) path between the two most recently selected nodes (this path may consists of numerous segments, if the two nodes are not adjacent to each other in the network), and changes every road segment on this path to a primary road segment. If there is no path in the network between the selected nodes, then nothing happens.

The MAKE-PATH-TERTIARY button selects a (shortest) path between the two most recently selected nodes.  This path must consist only of primary road segments.  If such a path does not exist, then nothing happens.

The SAVE-NETWORK button allows you to save your current road network as a file.   You will be prompted to choose a file name.  (It is recommended, though not necessary, that you give the file a meaningful extensions, such as "xxxxx.network".)

The LOAD-NETWORK button allows you to load a previously saved road network file.  

The "SHOW/HIDE INTERSECTIONS" button toggles whether the intersection nodes are displayed in the world view.  Temporarily hiding the nodes can give a better idea of what the road network actually looks like.

## EXTENDING THE MODEL

A simple extension to this model would be to include another basic setup pattern (like SETUP-GRID and SETUP-RADIAL).  Start by reading the code for the SETUP-GRID and SETUP-RADIAL procedures, and then design your own.  You may or ma not need to make modifications to the FINISH-SETUP procedure.

Another extension to this model would be to support curvy roads more directly, by changing the link shapes of the roads to a more curvy link shape (see the Link Shapes Editor, under the Tools menu).  In order for this change to also be reflected in the CITIES model, you would need to make changes to the file "import-road-network.nls", to have the turtles that create the road network move in curved patterns on their way to their destination.

## NETLOGO FEATURES

This model makes considerable use of the NetLogo's support for the links agent type.  It uses two different link breeds (one for primary roads, and one for tertiary roads).  It also makes use of one undocumented NetLogo primitive called __network-shortest-path-links, for the convenience of turning a whole path of road primary or tertiary with one click.  The functionality provided by this primitive will likely be officially supported and documented in some future release of NetLogo.

## RELATED MODELS

This model is a companion model, or extension, to the "Cities" model.  For other models that investigate topics related to urban development, see the "Urban Suite" models.

This model is a highly network-based model, and is thus related to several of the Network models in the Models Library, such as Preferential Attachment and Giant Component.

## CREDITS AND REFERENCES

This model was written by Forrest Sondahl in 2007, as a tool for developing transportation network structures that could be integrated into the Cities model.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Decision Making Time - Existing Plan" repetitions="10" runMetricsEveryStep="false">
    <setup>Reset</setup>
    <go>go</go>
    <metric>N_000</metric>
    <metric>N_001</metric>
    <metric>N_010</metric>
    <metric>N_011</metric>
    <metric>N_020</metric>
    <metric>N_021</metric>
    <metric>N_030</metric>
    <metric>N_031</metric>
    <metric>N_100</metric>
    <metric>N_101</metric>
    <metric>N_110</metric>
    <metric>N_111</metric>
    <metric>N_120</metric>
    <metric>N_121</metric>
    <metric>N_130</metric>
    <metric>N_131</metric>
    <enumeratedValueSet variable="Alternative-Plan-Mode">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceleration">
      <value value="0.0099"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deceleration">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immediate-evacuation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
