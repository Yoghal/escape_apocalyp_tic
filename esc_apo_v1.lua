-- title:   Escape Apocalyp-Tic
-- author:  Yoghal
-- desc:    Gamecodeur Community Gamejam 1 - Theme Survie et aléatoire
-- version: 0.1
-- script:  lua

--[[ note
	Gamecodeur Community Gamejam 1 - 9 fevrier a 17h au 19 fevrier a 12h
]]

function Clamp(pValue,pMin,pMax)
	if pValue<=pMin then return pMin
	elseif pValue>=pMax then return pMax end
	return pValue
end

function IntersectRectPoint(pRX,pRY,pRW,pRH,pPX,pPY)
	return pPX>=pRX and pPX<=pRX+pRW and pPY>=pRY and pPY<=pRY+pRH
end

function IntersectRectPointAABB(pMinX,pMinY,pMaxX,pMaxY,pPX,pPY)
	return pPX>=pMinX and pPX<=pMaxX and pPY>=pMinY and pPY<=pMaxY
end

function DistanceManathan(pX1,pY1,pX2,pY2)
	local dx=pX2-pX1
	local dy=pY2-pY1
	return math.abs(dx)+math.abs(dy),dx,dy
end

function Tween_EaseInSine(pStart, pEnd, pCurrentTime, pDuration)
	local c=(pEnd-pStart)
	return -c*math.cos(pCurrentTime/pDuration*(math.pi/2))+c+pStart
end

function Tween_EaseOutSine(pStart, pEnd, pCurrentTime, pDuration)
	return (pEnd-pStart)*math.sin(pCurrentTime/pDuration*(math.pi/2))+pStart
end

function PFAStar(pSLine,pSCol,pELine,pECol,pGrid)
	local newGrid={}
	local openSet={}
	local closeSet={}

	function include(item,list)
		for i,ele in ipairs(list) do
			if item==ele then
				return true
			end
		end
		return false
	end

	for l=1,#pGrid do
		newGrid[l]={}
		for c=1,#pGrid[l] do
			newGrid[l][c]={l=l,c=c,f=0,g=0,h=0,neighbors={},parent=nil}
		end
	end

	for l=1,#pGrid do
		for c=1,#pGrid[l] do
			local g=newGrid[l][c]
			if g.l<#newGrid then
				if pGrid[g.l+1][g.c]==0 or (g.l+1==pSLine and g.c==pSCol) or (g.l+1==pELine and g.c==pECol) then
					table.insert(g.neighbors,newGrid[g.l+1][g.c])
				end
			end
			if g.l>1 then
				if pGrid[g.l-1][g.c]==0 or (g.l-1==pSLine and g.c==pSCol) or (g.l-1==pELine and g.c==pECol) then
					table.insert(g.neighbors,newGrid[g.l-1][g.c])
				end
			end
			if g.c<#newGrid[g.l] then
				if pGrid[g.l][g.c+1]==0 or (g.l==pSLine and g.c+1==pSCol) or (g.l==pELine and g.c+1==pECol) then
					table.insert(g.neighbors,newGrid[g.l][g.c+1])
				end
			end
			if g.l>1 then
				if pGrid[g.l][g.c-1]==0 or (g.l==pSLine and g.c-1==pSCol) or (g.l==pELine and g.c-1==pECol) then
					table.insert(g.neighbors,newGrid[g.l][g.c-1])
				end
			end
		end
	end

	local newStart=newGrid[pSLine][pSCol]
	local newEnd=newGrid[pELine][pECol]
	table.insert(openSet,newStart)

	while #openSet>0 do
		local lowestIndex=1
		for i=1,#openSet do
			if openSet[i].f<openSet[lowestIndex].f then
				lowestIndex=i
				break
			end
		end
		local current=openSet[lowestIndex]
		if current==newEnd then
			local temp=current
			local path={}
			table.insert(path,{l=temp.l,c=temp.c})
			while temp.parent do
				table.insert(path,{l=temp.parent.l,c=temp.parent.c})
				temp=temp.parent
			end
			return path
		end
		table.remove(openSet,lowestIndex)
		table.insert(closeSet,current)
		local neighbors=current.neighbors
		for i=1,#neighbors do
			local neighbor=neighbors[i];
			if not include(neighbor,closeSet) then
				local possibleG=current.g+1
				local bool=true
				if not include(neighbor,openSet) then
					table.insert(openSet,neighbor)
				elseif possibleG>=neighbor.g then
					bool=false
				end
				if bool then
					neighbor.g=possibleG
					neighbor.h=DistanceManathan(neighbor.c,neighbor.l,newEnd.c,newEnd.l)
					neighbor.f=neighbor.g+neighbor.h
					neighbor.parent=current
				end
			end
		end
	end
	return nil;
end

function Lerp(pStart,pEnd,pPct)
	return pStart+(pEnd-pStart)*pPct
end

rnd=math.random
flr=math.floor
cos=math.cos
sin=math.sin
PI=math.pi

SCREEN={w=240,h=136}
BTNID={up=0,down=1,left=2,right=3,a=4,b=5,x=6,y=7}
SIZESPR=8
SIZEFONT=5.5
COLORID={BLACK=0,RED1=1,RED2=2,ORANGE=3,YELLOW=4,GREEN1=5,GREEN2=6,GREEN3=7,BLUE1=8,BLUE2=9,BLUE3=10,CYAN=11,WHITE=12,GRAY1=13,GRAY2=14,GRAY3=15}

btnState={
	oldIsDown={up=false,down=false,left=false,right=false},
	isDown={up=false,down=false,left=false,right=false},
	isReleased={up=false,down=false,left=false,right=false},
}

fTime={current=time(),last=time()}
dt=(fTime.current-fTime.last)/1000

sceneManager={currentScene="",swapScene="",stateScene="principal"}
listParticle={}

scSh={x=0,y=0,bounce={minX=-1,maxX=1,minY=-1,maxY=1},activate=false,time=0}
hitStop={activate=false,time=0}

worldMap={listMap={},nbMap=5,numMap=1,currentMap=nil}

player={
	l=0,c=0,dir="down",life=100,lifeMax=100,hunger=100,hungerMax=100,
	ammo=0,recul=false,firstBtnMove="",nbAxe=3
}

safetyZone={l=1,c=0}

INDEXMAP={void=0,player=1,safetyZone=2,food=3,fuelCan=4,obstacle=5,
	ammoBag=6,shelter=7,keyShelter=8,wolf=9,bandit=10,bandage=11,carTool=12}

listFood={}
listObstacle={}
listFuelCan={}
listAmmoBag={}
listBullet={}
listCarTool={}
listBandage={}
--listBox={}
listShelter={}
listKeyShelter={}

listWolf={}
listBandit={}

car={x=(SCREEN.w-SIZESPR*2)/2,y=SIZESPR+1,
	currentFuel=50,capacityFuelMax=100,currentDamage=100,
	beginFuel=50,endFuel=0
}

timerAtomicBomb={min={d=0,u=2},sec={d=0,u=0},timer=0,activateMusic=false}

phaseAnimMoveCar="move"
timerPauseCarAnim=0
carAnimObstacleInRoad=false
score=0
listDisplayScore={}
compteur={food=0,fuelCan=0,ammoBag=0,wolf=0,bandit=0}

function CreateScene(pNameScene,pfUpdate,pfDraw,pfStart,pfEnd)
	sceneManager[pNameScene]={
		fUpdate=pfUpdate,fDraw=pfDraw,fStart=pfStart,fEnd=pfEnd,
		transitionIn={finish=false,timer=0,activate=false},
		transitionOut={finish=false,timer=0,activate=false},
		listButton={},currentButton=1
	}
end

function InitTransitionScene(pTypeTransition,pTypeTransitionID)
	if not pTypeTransition.activate then return end
	for k,v in pairs(pTypeTransition.listBeginEnd) do
		for k2,v2 in pairs(v) do
			v2.value=v2.begin
		end
	end
end

function UpdateTransitionSceneAux(pTypeTransition)
	pTypeTransition.finish=true
	StateSceneTransition()
end

function UpdateTransitionScene(pTypeTransition,pbWithSST)
	if not pTypeTransition.activate then
		if pbWithSST then StateSceneTransition() end
		return
	end
	local element=pTypeTransition.listBeginEnd[sceneManager.swapScene]
	if element==nil then UpdateTransitionSceneAux(pTypeTransition)	return end
	pTypeTransition.timer=pTypeTransition.timer+dt
	if pTypeTransition.fTweening~=nil then
		for k,v in pairs(element) do
			v.value=pTypeTransition.fTweening(v.begin,v.endd,pTypeTransition.timer,pTypeTransition.duration)
		end
	end
	if pTypeTransition.timer>pTypeTransition.duration then
		pTypeTransition.timer=0
		for k,v in pairs(element) do
			v.value=v.endd
		end
		UpdateTransitionSceneAux(pTypeTransition)
	end
end

function UpdateScene()
	local currentScene=sceneManager[sceneManager.currentScene]
	if sceneManager.stateScene=="principal" then
		currentScene.fUpdate()
	elseif sceneManager.stateScene=="transitionIn" then
		UpdateTransitionScene(currentScene.transitionIn,true)
	elseif sceneManager.stateScene=="transitionOut" then
		UpdateTransitionScene(currentScene.transitionOut,true)
	end
end

function DrawScene()
	sceneManager[sceneManager.currentScene].fDraw()
end

function StateSceneTransition()
	local currentScene=sceneManager[sceneManager.currentScene]
	if sceneManager.stateScene=="principal" then
		InitTransitionScene(currentScene.transitionIn,"in")
		InitTransitionScene(currentScene.transitionOut,"out")
		sceneManager.stateScene="transitionOut"
	elseif sceneManager.stateScene=="transitionOut" then
		if currentScene.transitionOut.finish or not currentScene.transitionOut.activate then
			currentScene.transitionOut.finish=false
			ChangeCurrentSceneToNextScene()
			UpdateTransitionScene(sceneManager[sceneManager.currentScene].transitionIn,false)
			sceneManager.stateScene="transitionIn"
		end
	elseif sceneManager.stateScene=="transitionIn" then
		if currentScene.transitionIn.finish or not currentScene.transitionIn.activate then
			currentScene.transitionIn.finish=false
			InitTransitionScene(sceneManager[sceneManager.swapScene].transitionIn,"in")
			InitTransitionScene(sceneManager[sceneManager.swapScene].transitionOut,"out")
			sceneManager.stateScene="principal"
		end
	end
end

function SwitchScene(pNameScene)
	if sceneManager[pNameScene]==nil then return end
	if sceneManager.currentScene==pNameScene then return end
	if sceneManager.currentScene=="" then
		sceneManager.currentScene=pNameScene
	end
	sceneManager.swapScene=pNameScene
	StateSceneTransition()
end

function ChangeCurrentSceneToNextScene()
	if sceneManager[sceneManager.currentScene].fEnd~=nil then sceneManager[sceneManager.currentScene].fEnd() end
	local temp=sceneManager.currentScene
	sceneManager.currentScene=sceneManager.swapScene
	sceneManager.swapScene=temp
	if sceneManager[sceneManager.currentScene].fStart~=nil then sceneManager[sceneManager.currentScene].fStart() end
end

function SetTransitionSceneAux(pTypeTransition,pfTweening,pDuration)
	pTypeTransition.activate=true
	pTypeTransition.fTweening=pfTweening
	pTypeTransition.duration=pDuration
	pTypeTransition.listBeginEnd={}
end

function SetTransitionSceneIn(pNameScene,pfTweening,pDuration)
	local scene=sceneManager[pNameScene]
	if scene==nil then return end
	SetTransitionSceneAux(scene.transitionIn,pfTweening,pDuration)
end

function SetTransitionSceneOut(pNameScene,pfTweening,pDuration)
	local scene=sceneManager[pNameScene]
	if scene==nil then return end
	SetTransitionSceneAux(scene.transitionOut,pfTweening,pDuration)
end

function AddElementTransitionSceneAux(pTypeTransition,pNextScene,pNameElement,pBegin,pEnd,pTypeTransitionID)
	if pTypeTransition.listBeginEnd[pNextScene]==nil then
		pTypeTransition.listBeginEnd[pNextScene]={}
	end
	pTypeTransition.listBeginEnd[pNextScene][pNameElement]={begin=pBegin,endd=pEnd,value=0}
end

function AddElementTransitionSceneIn(pPrincipalScene,pNextScene,pNameElement,pBegin,pEnd)
	local scene=sceneManager[pPrincipalScene]
	if scene==nil then return end
	AddElementTransitionSceneAux(scene.transitionIn,pNextScene,pNameElement,pBegin,pEnd,"in")
end

function AddElementTransitionSceneOut(pPrincipalScene,pNextScene,pNameElement,pBegin,pEnd)
	local scene=sceneManager[pPrincipalScene]
	if scene==nil then return end
	AddElementTransitionSceneAux(scene.transitionOut,pNextScene,pNameElement,pBegin,pEnd,"out")
end

function GetValueTransitionSceneAux(pTypeTransition,pIndex)
	if pTypeTransition.listBeginEnd==nil then return 0 end
	local element=pTypeTransition.listBeginEnd[sceneManager.swapScene]
	if element==nil then return 0 end
	local element2=element[pIndex]
	if element2==nil then return 0 end
	return element2.value
end

function GetValueTransitionSceneIn(pNameScene,pIndex)
	local scene=sceneManager[pNameScene]
	if scene==nil then return 0 end
	return GetValueTransitionSceneAux(scene.transitionIn,pIndex)
end

function GetValueTransitionSceneOut(pNameScene,pIndex)
	local scene=sceneManager[pNameScene]
	if scene==nil then return 0 end
	return GetValueTransitionSceneAux(scene.transitionOut,pIndex)
end

function GetValueTransitionScene(pNameScene,pIndex)
	local scene=sceneManager[pNameScene]
	if scene==nil then return 0 end
	if sceneManager.stateScene=="principal" then
		return GetValueTransitionSceneAux(scene.transitionIn,pIndex)
	elseif sceneManager.stateScene=="transitionIn" then
		return GetValueTransitionSceneAux(scene.transitionIn,pIndex)
	elseif sceneManager.stateScene=="transitionOut" then
		return GetValueTransitionSceneAux(scene.transitionOut,pIndex)
	end
	return 0
end

function Particle_Rnd_RadianToDir(pAb,pAp)
	local rndDir=((math.random(0,100) / 100)*pAp)+pAb
	return cos(rndDir),sin(rndDir)
end

function Particle_Create(pX,pY,pVx,pVy,pLife,pSpeed,pColor,pbAcc)
	local newParticle={x=pX,y=pY,vx=pVx,vy=pVy,life=pLife,speed=pSpeed,color=pColor,bacc=pbAcc,acc=1}
	table.insert(listParticle,newParticle)
end

function Particle_Update()
	for i=#listParticle,1,-1 do
		local p=listParticle[i]
		p.life=p.life-dt

		if p.acc>=0 then
			if p.bacc then p.acc=p.acc-dt end
			p.x=p.x+p.vx*p.speed*dt*p.acc
			p.y=p.y+p.vy*p.speed*dt*p.acc
		end

		if p.life<0 then
			table.remove(listParticle,i)
		end
	end
end

function Particle_Draw()
	for i,v in ipairs(listParticle) do
		pix(v.x+scSh.x,v.y+scSh.y,v.color)
	end
end

function Paricle_Emitter_Walk(pLine,pCol,pDir)
	local rndNbParticle=rnd(3,6)
	local x,y=Map_PosLineColToPx(worldMap.currentMap,pCol,pLine)
	local ap,ab=0,0
	if pDir=="right" then
		ab,ap=3*PI/4,PI/2
	elseif pDir=="left" then
		ab,ap=-PI/4,PI/2
	elseif pDir=="down" then
		ab,ap=-PI/4,-PI/2
	elseif pDir=="up" then
		ab,ap=PI/4,PI/2
	end
	for i=1,rndNbParticle do
		local rndCos,rndSin=Particle_Rnd_RadianToDir(ab,ap)
		Particle_Create(x+SIZESPR/2,y+SIZESPR,rndCos,rndSin,rnd(50,100)/100,rnd(5,10),COLORID.GRAY3,false)
	end
end

function Paricle_Emitter_Shot(pLine,pCol,pDir)
	local rndNbParticle=rnd(6,9)
	local x,y=Map_PosLineColToPx(worldMap.currentMap,pCol,pLine)
	local ap,ab=0,0
	local sx,sy=0,0
	if pDir=="right" then
		ab,ap=-PI/4,PI/2
		sx,sy=SIZESPR,SIZESPR/2
	elseif pDir=="left" then
		ab,ap=3*PI/4,PI/2
		sx,sy=0,SIZESPR/2
	elseif pDir=="down" then
		ab,ap=PI/4,PI/2
		sx,sy=SIZESPR/2,SIZESPR
	elseif pDir=="up" then
		ab,ap=-PI/4,-PI/2
		sx,sy=SIZESPR/2,0
	end
	for i=1,rndNbParticle do
		local rndCos,rndSin=Particle_Rnd_RadianToDir(ab,ap)
		Particle_Create(x+sx,y+sy,rndCos,rndSin,rnd(10,20)/100,rnd(40,60),COLORID.RED2,false)
	end
end

function Paricle_Emitter_BulletFly(pLine,pCol,pDir)
	local rndNbParticle=rnd(5,7)
	local x,y=Map_PosLineColToPx(worldMap.currentMap,pCol,pLine)
	local ap,ab=0,0
	if pDir=="right" then
		ab,ap=3*PI/4,PI/2
	elseif pDir=="left" then
		ab,ap=-PI/4,PI/2
	elseif pDir=="down" then
		ab,ap=-PI/4,-PI/2
	elseif pDir=="up" then
		ab,ap=PI/4,PI/2
	end
	for i=1,rndNbParticle do
		local rndCos,rndSin=Particle_Rnd_RadianToDir(ab,ap)
		Particle_Create(x+SIZESPR/2,y+SIZESPR/2,rndCos,rndSin,rnd(10,20)/100,rnd(10,20),COLORID.ORANGE,false)
	end
end

function Paricle_Emitter_BulletDie(pLine,pCol,pDir)
	local rndNbParticle=rnd(10,15)
	local x,y=Map_PosLineColToPx(worldMap.currentMap,pCol,pLine)
	local ap,ab=0,0
	local sx,sy=0,0
	if pDir=="right" then
		ab,ap=PI/2,PI
		sx,sy=0,SIZESPR/2
	elseif pDir=="left" then
		ab,ap=PI/2,-PI
		sx,sy=SIZESPR,SIZESPR/2
	elseif pDir=="down" then
		ab,ap=0,-PI
		sx,sy=SIZESPR/2,0
	elseif pDir=="up" then
		ab,ap=0,PI
		sx,sy=SIZESPR/2,SIZESPR
	end
	for i=1,rndNbParticle do
		local rndCos,rndSin=Particle_Rnd_RadianToDir(ab,ap)
		Particle_Create(x+sx,y+sy,rndCos,rndSin,rnd(20,30)/100,rnd(20,40),COLORID.YELLOW,false)
	end
end

function Paricle_Emitter_Blood(pLine,pCol,pDir)
	local rndNbParticle=rnd(25,50)
	local x,y=Map_PosLineColToPx(worldMap.currentMap,pCol,pLine)
	local ap,ab=0,0
	if pDir=="right" then
		ab,ap=PI/2,-PI
	elseif pDir=="left" then
		ab,ap=PI/2,PI
	elseif pDir=="down" then
		ab,ap=0,PI
	elseif pDir=="up" then
		ab,ap=0,-PI
	end
	for i=1,rndNbParticle do
		local rndCos,rndSin=Particle_Rnd_RadianToDir(ab,ap)
		Particle_Create(x+SIZESPR/2,y+SIZESPR/2,rndCos,rndSin,rnd(75,100)/100,rnd(20,40),COLORID.RED2,true)
	end
end

function Paricle_Emitter_GetObject(pLine,pCol,pColor)
	local rndNbParticle=rnd(40,60)
	local x,y=Map_PosLineColToPx(worldMap.currentMap,pCol,pLine)
	for i=1,rndNbParticle do
		local rndCos,rndSin=Particle_Rnd_RadianToDir(0,2*PI)
		Particle_Create(x+SIZESPR/2,y+SIZESPR/2,rndCos,rndSin,rnd(75,100)/100,rnd(20,40),pColor,true)
	end
end

function Paricle_Emitter_CarMove()
	local rndNbParticle=rnd(2,4)
	for i=1,rndNbParticle do
		local rndCos,rndSin=Particle_Rnd_RadianToDir(3*PI/4,PI/2)
		Particle_Create(car.x+SIZESPR+SIZESPR/2,car.y+SIZESPR-1,rndCos,rndSin,rnd(50,100)/100,rnd(5,10),COLORID.GRAY3,false)
	end
end

function Paricle_Emitter_CarFlame()
	local rndNbParticle=rnd(2,4)
	local pct=1-car.currentDamage/100
	local lRMin,lRMax=flr(Lerp(0,75,pct)),flr(Lerp(0,150,pct))
	local lOMin,lOMax=flr(Lerp(0,50,pct)),flr(Lerp(0,75,pct))
	local lYMin,lYMax=flr(Lerp(0,25,pct)),flr(Lerp(0,50,pct))
	for i=1,rndNbParticle do
		local rndCos,rndSin=Particle_Rnd_RadianToDir(-PI/4,-PI/2)
		local lifeRed=rnd(lRMin,lRMax)/100
		local lifeOrange=rnd(lOMin,lOMax)/100
		local lifeYellow=rnd(lYMin,lYMax)/100
		Particle_Create(car.x+SIZESPR,car.y+SIZESPR/2,rndCos,rndSin,lifeRed,rnd(5,10),COLORID.RED2,false)
		Particle_Create(car.x+SIZESPR,car.y+SIZESPR/2,rndCos,rndSin,lifeOrange,rnd(5,10),COLORID.ORANGE,false)
		Particle_Create(car.x+SIZESPR,car.y+SIZESPR/2,rndCos,rndSin,lifeYellow,rnd(5,10),COLORID.YELLOW,false)
	end
end

function ScreenShake_Init()
	scSh.activate=false
	scSh.x=0
	scSh.y=0
	scSh.time=0
	scSh.bounce.minX=-1
	scSh.bounce.maxX=1
	scSh.bounce.minY=-1
	scSh.bounce.maxY=1
end

function ScreenShake_Activate(pTime)
	scSh.activate=true
	scSh.time=scSh.time+pTime
	scSh.time=Clamp(scSh.time,0,1)
end

function ScreenShake_ActivatePro(pTime,pBounceMinX,pBounceMaxX,pBounceMinY,pBounceMaxY)
	scSh.activate=true
	scSh.time=scSh.time+pTime
	scSh.time=Clamp(scSh.time,0,1)
	scSh.bounce.minX=pBounceMinX
	scSh.bounce.maxX=pBounceMaxX
	scSh.bounce.minY=pBounceMinY
	scSh.bounce.maxY=pBounceMaxY
end

function ScreenShake_Update()
	if scSh.activate then
		scSh.time=scSh.time-dt
		scSh.x=math.random(scSh.bounce.minX,scSh.bounce.maxX)
		scSh.y=math.random(scSh.bounce.minY,scSh.bounce.maxY)
		if scSh.time<=0 then
			ScreenShake_Init()
		end
	end
end

function HitStop_Activate(pTime)
	hitStop.activate=true
	hitStop.time=pTime
end

function HitStop_Update()
	if hitStop.activate then
		hitStop.time=hitStop.time-dt
		if hitStop.time<=0 then
			hitStop.activate=false
			hitStop.time=0
		end
		return true
	end
	return false
end

function WorldMap_Create()
	for i=1,worldMap.nbMap do
		Map_Create()
	end
end

function WorldMap_Generate()
	worldMap.numMap=1
	worldMap.currentMap=worldMap.listMap[worldMap.numMap]

	for i,v in ipairs(worldMap.listMap) do
		Map_Generate(v,i)
	end
end

function WorldMap_DrawGUI()
	local x,y,hMap=SCREEN.w-8+scSh.x,0,SCREEN.h/worldMap.nbMap
	for i=1,worldMap.nbMap do
		local color=0
		y=(i-0.5)*hMap+scSh.y
		if i<worldMap.numMap then
			color=COLORID.GREEN2
		elseif i>worldMap.numMap then
			color=COLORID.RED2
		end
		circ(x,y,6,color)
		if i<worldMap.nbMap then
			line(x,y,x,(i+0.5)*hMap+scSh.y,COLORID.WHITE)
		end
		circ(x,y,6,color)
		circb(x,y,6,COLORID.WHITE)
	end
	circb(x,(worldMap.numMap-0.5)*hMap+scSh.y,6,COLORID.RED2)
	spr(16,x-SIZESPR,y-SIZESPR,0,1,0,0,2,2)
	spr(273,x-SIZESPR/2,(worldMap.numMap-0.5)*hMap-SIZESPR/2+scSh.y,0)

	if worldMap.numMap<worldMap.nbMap then
		x=SCREEN.w-12+scSh.x
		y=(worldMap.numMap)*hMap+scSh.y
		line(x,y,SCREEN.w-4+scSh.x,y,COLORID.WHITE)
		x=x-16
		print("-"..worldMap.currentMap.costFuelNextMap,x,y-2,COLORID.WHITE)
		spr(258,x-10,y-4,0)
	end
end

function WorldMap_SceneWorldMap_DrawGUI()
	local x,y,wMap=0,SCREEN.h-16+scSh.y,SCREEN.w/worldMap.nbMap
	for i=1,worldMap.nbMap do
		local color=0
		x=(i-0.5)*wMap+scSh.x
		if i<worldMap.numMap then
			color=COLORID.GREEN2
		elseif i>worldMap.numMap then
			color=COLORID.RED2
		end
		circ(x,y,6,color)
		if i<worldMap.nbMap then
			line(x,y,(i+0.5)*wMap+scSh.x,y,COLORID.WHITE)
		end
		circ(x,y,6,color)
		circb(x,y,6,COLORID.WHITE)
	end
	circb((worldMap.numMap-0.5)*wMap+scSh.x,y,6,COLORID.RED2)

	spr(16,x-SIZESPR,y-SIZESPR,0,1,0,0,2,2)
	local text="Shelter"
	print(text,x-(#text*SIZEFONT)/2,y+SIZESPR+1,COLORID.WHITE)
end

function WorldMap_NextCurrentMap()
	worldMap.numMap=worldMap.numMap+1
	worldMap.numMap=Clamp(worldMap.numMap,1,worldMap.nbMap)
	worldMap.currentMap=worldMap.listMap[worldMap.numMap]
	Game_LoadMap()
end

function WorldMap_PrviousCurrentMap()
	worldMap.numMap=worldMap.numMap-1
	worldMap.numMap=Clamp(worldMap.numMap,1,worldMap.nbMap)
	worldMap.currentMap=worldMap.listMap[worldMap.numMap]
	Game_LoadMap()
end

function WorldMap_CheckNextCurrentMap()
	if car.currentFuel<=0 then
		SwitchScene("gameover")
		return
	end
	if car.currentDamage<=0 then
		SwitchScene("gameover")
		return
	end

	WorldMap_NextCurrentMap()
end

----------------------------------------------------------------------------------------------------

function Map_Create()
	local newMap={
		line=14,col=19,cell={},costFuelNextMap=rnd(30,40),riskDamageCar=rnd(10,90),costDamageCar=rnd(20,40)
	}
	newMap.offSet={x=(SCREEN.w-newMap.col*SIZESPR)/2,y=(SCREEN.h-newMap.line*SIZESPR)/2+SIZESPR}
	table.insert(worldMap.listMap,newMap)
end

function Map_RndElement(pMap,pLineMin,pLineMax,pColMin,pColMax)
	local rndL,rndC=0,0
	repeat
		rndL,rndC=rnd(pLineMin,pLineMax),rnd(pColMin,pColMax)
	until Map_GetIndex(pMap,rndL,rndC)==0 or
		(safetyZone.l==rndL and safetyZone.c==rndC) or
		(safetyZone.l+1==rndL and safetyZone.c==rndC)
	return rndL,rndC
end

function Map_Generate(pMap,pIndex)
	for l=1,pMap.line do
		if pMap.cell[l]==nil then pMap.cell[l]={} end
		for c=1,pMap.col do
			pMap.cell[l][c]=INDEXMAP.void
		end
	end

	SafetyZone_Init()

	local rndL,rndC=0,0
	local rndAmont=rnd(2,3)
	for i=1,rndAmont do
		rndL,rndC=Map_RndElement(pMap,2,pMap.line,1,pMap.col)
		Map_SetIndex(pMap,rndL,rndC,INDEXMAP.food)
	end

	if pIndex<worldMap.nbMap then
		rndAmont=rnd(2,3)
		for i=1,rndAmont do
			rndL,rndC=Map_RndElement(pMap,4,pMap.line,1,pMap.col)
			Map_SetIndex(pMap,rndL,rndC,INDEXMAP.fuelCan)
		end
	end

	rndAmont=rnd(2,3)
	for i=1,rndAmont do
		rndL,rndC=Map_RndElement(pMap,4,pMap.line,1,pMap.col)
		Map_SetIndex(pMap,rndL,rndC,INDEXMAP.ammoBag)
	end

	rndAmont=rnd(20,25)
	for i=1,rndAmont do
		rndL,rndC=Map_RndElement(pMap,1,pMap.line,1,pMap.col)
		Map_SetIndex(pMap,rndL,rndC,INDEXMAP.obstacle)
	end

	if pIndex<3 then
		rndAmont=rnd(2,4)
		for i=1,rndAmont do
			rndL,rndC=Map_RndElement(pMap,flr(pMap.line/2),pMap.line,1,pMap.col)
			Map_SetIndex(pMap,rndL,rndC,INDEXMAP.wolf)
		end
		if pIndex>1 then
			rndL,rndC=Map_RndElement(pMap,flr(pMap.line/2),pMap.line,1,pMap.col)
			Map_SetIndex(pMap,rndL,rndC,INDEXMAP.carTool)
		end
	else
		rndAmont=rnd(2,4)
		for i=1,rndAmont do
			rndL,rndC=Map_RndElement(pMap,flr(pMap.line/2),pMap.line,1,pMap.col)
			Map_SetIndex(pMap,rndL,rndC,INDEXMAP.bandit)
		end
	end

	if pIndex==worldMap.nbMap then
		rndL,rndC=Map_RndElement(pMap,flr(pMap.line/2),pMap.line,1,flr(pMap.col/2)-2)
		Map_SetIndex(pMap,rndL,rndC,INDEXMAP.shelter)

		rndL,rndC=Map_RndElement(pMap,flr(pMap.line/2),pMap.line,flr(pMap.col/2)+2,pMap.col)
		Map_SetIndex(pMap,rndL,rndC,INDEXMAP.keyShelter)
	end
end

function Map_Draw()
	local map=worldMap.currentMap
	rectb(map.offSet.x-1+scSh.x,map.offSet.y-1+scSh.y,map.col*SIZESPR+2,map.line*SIZESPR+2,COLORID.WHITE)
	SafetyZone_Draw()
end

function Map_PosLineColToPx(pMap,pCol,pLine)
	return pMap.offSet.x+(pCol-1)*SIZESPR,pMap.offSet.y+(pLine-1)*SIZESPR
end

function Map_SetIndex(pMap,pLine,pCol,pIndex)
	if not IntersectRectPoint(1,1,pMap.col-1,pMap.line-1,pCol,pLine) then	return end
	pMap.cell[pLine][pCol]=pIndex
end

function Map_GetIndex(pMap,pLine,pCol)
	if not IntersectRectPoint(1,1,pMap.col-1,pMap.line-1,pCol,pLine) then return -1 end
	return pMap.cell[pLine][pCol]
end

function Obstacle_Create(pLine,pCol)
	local newObs={
		l=pLine,c=pCol
	}
	table.insert(listObstacle,newObs)
end

function Obstacle_Draw()
	for i,v in ipairs(listObstacle) do
		local x,y=Map_PosLineColToPx(worldMap.currentMap,v.c,v.l)
		spr(286,x+scSh.x,y+scSh.y,0)
	end
end

function Food_Create(pLine,pCol)
	local newFood={
		l=pLine,c=pCol,amount=rnd(25,50)
	}
	table.insert(listFood,newFood)
end

function Food_Draw()
	for i,v in ipairs(listFood) do
		local x,y=Map_PosLineColToPx(worldMap.currentMap,v.c,v.l)
		spr(260,x+scSh.x,y+scSh.y,0)
	end
end

function FuelCan_Create(pLine,pCol)
	local newFuelCan={
		l=pLine,c=pCol,amount=rnd(10,15)
	}
	table.insert(listFuelCan,newFuelCan)
end

function FuelCan_Draw()
	for i,v in ipairs(listFuelCan) do
		local x,y=Map_PosLineColToPx(worldMap.currentMap,v.c,v.l)
		spr(258,x+scSh.x,y+scSh.y,0)
	end
end

function AmmoBag_Create(pLine,pCol)
	local newAmmoBag={
		l=pLine,c=pCol,amount=rnd(2,3)
	}
	table.insert(listAmmoBag,newAmmoBag)
end

function AmmoBag_Draw()
	for i,v in ipairs(listAmmoBag) do
		local x,y=Map_PosLineColToPx(worldMap.currentMap,v.c,v.l)
		spr(263,x+scSh.x,y+scSh.y,0)
	end
end

function Bandage_Create(pLine,pCol)
	local newBandage={
		l=pLine,c=pCol,amount=rnd(10,20)
	}
	table.insert(listBandage,newBandage)
end

function Bandage_Draw()
	for i,v in ipairs(listBandage) do
		local x,y=Map_PosLineColToPx(worldMap.currentMap,v.c,v.l)
		Map_SetIndex(worldMap.currentMap,v.l,v.c,INDEXMAP.bandage)
		spr(365,x+scSh.x,y+scSh.y,0)
	end
end

function CarTool_Create(pLine,pCol)
	local newCarTool={
		l=pLine,c=pCol,amount=rnd(10,15)
	}
	table.insert(listCarTool,newCarTool)
end

function CarTool_Draw()
	for i,v in ipairs(listCarTool) do
		local x,y=Map_PosLineColToPx(worldMap.currentMap,v.c,v.l)
		spr(264,x+scSh.x,y+scSh.y,0)
	end
end

function Shelter_Create(pLine,pCol)
	local newShelter={
		l=pLine,c=pCol,isLock=true
	}
	table.insert(listShelter,newShelter)
end

function Shelter_Draw()
	for i,v in ipairs(listShelter) do
		local x,y=Map_PosLineColToPx(worldMap.currentMap,v.c,v.l)
		local index=319
		if v.isLock then index=319
		elseif not v.isLock then index=335 end
		Map_SetIndex(worldMap.currentMap,v.l,v.c,INDEXMAP.shelter)
		spr(index,x+scSh.x,y+scSh.y,0)
	end
end

function KeyShelter_Create(pLine,pCol)
	local newKeyShelter={
		l=pLine,c=pCol
	}
	table.insert(listKeyShelter,newKeyShelter)
end

function KeyShelter_Draw()
	for i,v in ipairs(listKeyShelter) do
		local x,y=Map_PosLineColToPx(worldMap.currentMap,v.c,v.l)
		spr(351,x+scSh.x,y+scSh.y,0)
	end
end

function Bullet_Create(pLine,pCol,pDir,pBelong)
	local newBullet={
		l=pLine,c=pCol,dir=pDir,belong=pBelong
	}
	table.insert(listBullet,newBullet)
end

function Bullet_IntersectElement(pBullet)
	local index=Map_GetIndex(worldMap.currentMap,pBullet.l,pBullet.c)
	if index==-1 then
		sfx(8)
		return true
	elseif index==INDEXMAP.food then
		return false
	elseif index==INDEXMAP.obstacle then
		sfx(8)
		return IntersectBulletObstacle(pBullet)
	elseif index==INDEXMAP.fuelCan then
		return false
	elseif index==INDEXMAP.ammoBag then
		return false
	elseif index==INDEXMAP.wolf and pBullet.belong=="player" then
		DisplayScore_PosLineColToPx_Create(pBullet.l,pBullet.c,20,COLORID.RED2)
		HitStop_Activate(0.1)
		compteur.wolf=compteur.wolf+1
		sfx(5)
		return IntersectBulletWolf(pBullet)
	elseif index==INDEXMAP.bandit and pBullet.belong=="player" then
		DisplayScore_PosLineColToPx_Create(pBullet.l,pBullet.c,40,COLORID.RED2)
		HitStop_Activate(0.1)
		compteur.bandit=compteur.bandit+1
		sfx(5)
		return IntersectBulletBandit(pBullet)
	elseif index==INDEXMAP.player and pBullet.belong=="bandit" then
		ScreenShake_Activate(0.4)
		Player_SetLife(-20)
		Paricle_Emitter_Blood(player.l,player.c,pBullet.dir)
		sfx(6)
		return true
	end
	return false
end

function Bullet_Update()
	for i=#listBullet,1,-1 do
		local bullet=listBullet[i]
		if bullet.dir=="right" then
			bullet.c=bullet.c+1
		elseif bullet.dir=="left" then
			bullet.c=bullet.c-1
		elseif bullet.dir=="down" then
			bullet.l=bullet.l+1
		elseif bullet.dir=="up" then
			bullet.l=bullet.l-1
		end

		if Bullet_IntersectElement(bullet) then
			Paricle_Emitter_BulletDie(bullet.l,bullet.c,bullet.dir)
			table.remove(listBullet,i)
		else
			Paricle_Emitter_BulletFly(bullet.l,bullet.c,bullet.dir)
		end
	end
end

function Bullet_Draw()
	for i,v in ipairs(listBullet) do
		local x,y=Map_PosLineColToPx(worldMap.currentMap,v.c,v.l)
		local rotation=0
		if v.dir=="right" then
			rotation=0
		elseif v.dir=="left" then
			rotation=2
		elseif v.dir=="down" then
			rotation=1
		elseif v.dir=="up" then
			rotation=3
		end
		spr(279,x+scSh.x,y+scSh.y,0,1,0,rotation)
	end
end

----------------------------------------------------------------------------------------------------

function Player_LoadMap()
	player.l=safetyZone.l
	player.c=safetyZone.c
	player.dir="down"
	player.firstBtnMove=""
	Map_SetIndex(worldMap.currentMap,player.l,player.c,INDEXMAP.player)
end

function Player_Init()
	Player_LoadMap()
	player.life=100
	player.lifeMax=100
	player.hunger=100
	player.hungerMax=100
	player.ammo=0
	player.recul=false
	player.nbAxe=3
end

function Player_SetHunger(pAmount)
	player.hunger=player.hunger+pAmount
	player.hunger=Clamp(player.hunger,0,player.hungerMax)
end

function Player_SetLife(pAmount)
	player.life=player.life+pAmount
	player.life=Clamp(player.life,0,player.lifeMax)
end

function Player_SetAmmo(pAmount)
	player.ammo=player.ammo+pAmount
	player.ammo=Clamp(player.ammo,0,99)
end

function Player_Move(pAmountLine,pAmountCol)
	local oldLine,oldCol=player.l,player.c
	player.l=player.l+pAmountLine
	player.c=player.c+pAmountCol

	if Player_IntersectElement()==-1 then
		player.l=oldLine
		player.c=oldCol
		return
	end

	Map_SetIndex(worldMap.currentMap,oldLine,oldCol,0)
	Map_SetIndex(worldMap.currentMap,player.l,player.c,INDEXMAP.player)
	Paricle_Emitter_Walk(player.l,player.c,player.dir)
end

function Player_IntersectElement()
	local index=Map_GetIndex(worldMap.currentMap,player.l,player.c)
	if index==-1 then return -1 end
	if index==INDEXMAP.food then
		IntersectPlayerFood()
		Paricle_Emitter_GetObject(player.l,player.c,COLORID.YELLOW)
		DisplayScore_PosLineColToPx_Create(player.l,player.c,100,COLORID.YELLOW)
		compteur.food=compteur.food+1
		sfx(1)
		return 0
	elseif index==INDEXMAP.obstacle then
		return -1
	elseif index==INDEXMAP.fuelCan then
		IntersectPlayerFuelCan()
		Paricle_Emitter_GetObject(player.l,player.c,COLORID.ORANGE)
		DisplayScore_PosLineColToPx_Create(player.l,player.c,50,COLORID.ORANGE)
		compteur.fuelCan=compteur.fuelCan+1
		sfx(4)
		return 0
	elseif index==INDEXMAP.ammoBag then
		IntersectPlayerAmmoBag()
		Paricle_Emitter_GetObject(player.l,player.c,COLORID.GRAY2)
		DisplayScore_PosLineColToPx_Create(player.l,player.c,10,COLORID.GRAY2)
		compteur.ammoBag=compteur.ammoBag+1
		sfx(7)
		return 0
	elseif index==INDEXMAP.bandage then
		IntersectPlayerBandage()
		Paricle_Emitter_GetObject(player.l,player.c,COLORID.RED2)
		sfx(12)
		return 0
	elseif index==INDEXMAP.carTool then
		IntersectPlayerCarTool()
		Paricle_Emitter_GetObject(player.l,player.c,COLORID.GRAY2)
		sfx(7)
		return 0
	elseif index==INDEXMAP.shelter then
		IntersectPlayerShelter()
		return 0
	elseif index==INDEXMAP.keyShelter then
		IntersectPlayerKeyShelter()
		Paricle_Emitter_GetObject(player.l,player.c,COLORID.GRAY1)
		sfx(11)
		return 0
	elseif index==INDEXMAP.wolf then
		Player_SetLife(-10)
		ScreenShake_Activate(0.3)
		sfx(6)
		return -1
	elseif index==INDEXMAP.bandit then
		Player_SetLife(-10)
		ScreenShake_Activate(0.3)
		sfx(6)
		return -1
	end
	Player_SetHunger(-1)
	sfx(0)
	return 0
end

function Player_Shot()
	if player.ammo>0 then
		local bMinX,bMaxX,bMinY,bMaxY=-1,1,-1,1
		player.recul=true
		Bullet_Create(player.l,player.c,player.dir,"player")
		Player_SetAmmo(-1)
		if player.dir=="right" then
			bMinX,bMaxX,bMinY,bMaxY=-1,0,0,0
		elseif player.dir=="left" then
			bMinX,bMaxX,bMinY,bMaxY=0,1,0,0
		elseif player.dir=="down" then
			bMinX,bMaxX,bMinY,bMaxY=0,0,-1,0
		elseif player.dir=="up" then
			bMinX,bMaxX,bMinY,bMaxY=0,0,0,1
		end
		ScreenShake_ActivatePro(0.2,bMinX,bMaxX,bMinY,bMaxY)
		Paricle_Emitter_Shot(player.l,player.c,player.dir)
		sfx(2)
	else
		sfx(9)
	end
end

function Player_Update()
	local hold=8
	local period=10
	player.recul=false
	if (btnState.isReleased.up and player.firstBtnMove=="up") or
		(btnState.isReleased.down and player.firstBtnMove=="down") or
		(btnState.isReleased.left and player.firstBtnMove=="left") or
		(btnState.isReleased.right and player.firstBtnMove=="right") then
		player.firstBtnMove=""
	end

	if btnp(BTNID.up,hold,period) and not btnState.isDown.down and
		(player.firstBtnMove=="up" or player.firstBtnMove=="") then
		local nextMap=false
		if player.dir=="up" then
			if player.l==safetyZone.l and player.c==safetyZone.c
				and worldMap.numMap<worldMap.nbMap then
				nextMap=true
			end
			Player_Move(-1,0)
		else
			player.firstBtnMove="up"
			player.dir="up"
		end
		if nextMap then Car_SetMove(2) end
	elseif btnp(BTNID.down,hold,period) and not btnState.isDown.up and
		(player.firstBtnMove=="down" or player.firstBtnMove=="") then
		if player.dir=="down" then
			Player_Move(1,0)
		else
			player.firstBtnMove="down"
			player.dir="down"
		end
	elseif btnp(BTNID.left,hold,period) and not btnState.isDown.right and
		(player.firstBtnMove=="left" or player.firstBtnMove=="") then
		if player.dir=="left" then
			Player_Move(0,-1)
		else
			player.firstBtnMove="left"
			player.dir="left"
		end
	elseif btnp(BTNID.right,hold,period) and not btnState.isDown.left and
		(player.firstBtnMove=="right" or player.firstBtnMove=="") then
		if player.dir=="right" then
			Player_Move(0,1)
		else
			player.firstBtnMove="right"
			player.dir="right"
		end
	end

	if btnp(BTNID.a) then Player_Shot() end
	if btnp(BTNID.b) and player.nbAxe>0 then
		local lineNeighbor=0
		local colNeighbor=0
		if player.dir=="right" and player.c<worldMap.currentMap.col then
			colNeighbor=1
		elseif player.dir=="left" and player.c>1 then
			colNeighbor=-1
		elseif player.dir=="down" and player.l<worldMap.currentMap.line then
			lineNeighbor=1
		elseif player.dir=="up" and player.l>1 then
			lineNeighbor=-1
		end
		local index=Map_GetIndex(worldMap.currentMap,player.l+lineNeighbor,player.c+colNeighbor)
		if index==INDEXMAP.obstacle then
			for i=#listObstacle,1,-1 do
				local obstacle=listObstacle[i]
				if player.l+lineNeighbor==obstacle.l and player.c+colNeighbor==obstacle.c then
					sfx(13)
					Map_SetIndex(worldMap.currentMap,obstacle.l,obstacle.c,0)
					player.nbAxe=player.nbAxe-1
					player.nbAxe=Clamp(player.nbAxe,0,3)
					table.remove(listObstacle,i)
					break
				end
			end
		end
	end
	Player_SetHunger(-dt)
	if player.life<=0 or player.hunger<=0 then
		SwitchScene("gameover")
	end
end

function Player_Draw()
	local x,y=Map_PosLineColToPx(worldMap.currentMap,player.c,player.l)
	local rx,ry=0,0
	local index=273
	if player.dir=="right" then
		index=274
		if player.recul then rx=-1 end
	elseif player.dir=="left" then
		index=275
		if player.recul then rx=1 end
	elseif player.dir=="down" then
		index=276
		if player.recul then ry=-1 end
	elseif player.dir=="up" then
		index=277
		if player.recul then ry=1 end
	end
	spr(index,x+rx+scSh.x,y+ry+scSh.y,0)
end

function Player_DrawGUI()
	local barreW=40
	local barreH=5
	local x=1+scSh.x
	local y=1+scSh.y
	spr(334,x,y,0,1)
	spr(262,x,y+SIZESPR+1,0,1)
	for i=1,player.nbAxe do
		spr(367,x+(i-1)*SIZESPR,y+SIZESPR*2+3,0)
	end
	if player.nbAxe>0 then
		print("[B]",x+player.nbAxe*SIZESPR,y+SIZESPR*2+3,COLORID.WHITE)
	end
	x=x+SIZESPR+2
	y=y+2
	rect(x,y,player.life*barreW/player.lifeMax,barreH,COLORID.GREEN3)
	rectb(x,y,barreW,barreH,COLORID.WHITE)
	y=y+SIZESPR/2-1
	rect(x,y+1+barreH,player.hunger*barreW/player.hungerMax,barreH,COLORID.ORANGE)
	rectb(x,y+1+barreH,barreW,barreH,COLORID.WHITE)

	spr(263,1+scSh.x,SCREEN.h-SIZESPR*2-1+scSh.y,0,2)
	print(player.ammo.." [A]",1+scSh.x+SIZESPR*2,SCREEN.h-SIZEFONT-2+scSh.y,COLORID.WHITE)
end

function Wolf_Create(pLine,pCol)
	local newWolf={
		l=pLine,c=pCol,dir="right",state="normal",timerMove=0,durationMove=rnd(100,200)/100
	}
	table.insert(listWolf,newWolf)
end

function Wolf_Move(pWolf,pAmountLine,pAmountCol)
	local oldLine,oldCol=pWolf.l,pWolf.c
	pWolf.l=pWolf.l+pAmountLine
	pWolf.c=pWolf.c+pAmountCol
	if pAmountCol>0 then
		pWolf.dir="right"
	elseif pAmountLine>0 then
		pWolf.dir="down"
	elseif pAmountCol<0 then
		pWolf.dir="left"
	elseif pAmountLine<0 then
		pWolf.dir="up"
	end

	if Wolf_IntersectElement(pWolf)==-1 then
		pWolf.l=oldLine
		pWolf.c=oldCol
		return
	end

	Map_SetIndex(worldMap.currentMap,oldLine,oldCol,0)
	Map_SetIndex(worldMap.currentMap,pWolf.l,pWolf.c,INDEXMAP.wolf)
	Paricle_Emitter_Walk(pWolf.l,pWolf.c,pWolf.dir)
end

function Wolf_IntersectElement(pWolf)
	local index=Map_GetIndex(worldMap.currentMap,pWolf.l,pWolf.c)
	if index==-1 then return -1 end
	if index==INDEXMAP.food then
		return -1
	elseif index==INDEXMAP.obstacle then
		return -1
	elseif index==INDEXMAP.fuelCan then
		return -1
	elseif index==INDEXMAP.ammoBag then
		return -1
	elseif index==INDEXMAP.bandage then
		return -1
	elseif index==INDEXMAP.shelter then
		return -1
	elseif index==INDEXMAP.keyShelter then
		return -1
	elseif index==INDEXMAP.wolf then
		return -1
	elseif index==INDEXMAP.bandit then
		return -1
	elseif index==INDEXMAP.player then
		ScreenShake_Activate(0.3)
		Player_SetLife(-10)
		Paricle_Emitter_Blood(player.l,player.c,pWolf.dir)
		sfx(6)
		return -1
	end
	return 0
end

function Wolf_State_Normal(pWolf)
	pWolf.timerMove=pWolf.timerMove+dt
	if pWolf.timerMove>pWolf.durationMove then
		pWolf.timerMove=0
		pWolf.durationMove=rnd(100,200)/100
		local rndDir=rnd(1,4)
		if rndDir==1 then
			Wolf_Move(pWolf,0,1)
		elseif rndDir==2 then
			Wolf_Move(pWolf,1,0)
		elseif rndDir==3 then
			Wolf_Move(pWolf,0,-1)
		elseif rndDir==4 then
			Wolf_Move(pWolf,-1,0)
		end
	end

	if IntersectRectPointAABB(pWolf.c-5,pWolf.l-5,pWolf.c+5,pWolf.l+5,player.c,player.l) then
		pWolf.timerMove=0
		pWolf.state="pursuit"
	end
end

function Wolf_State_Pursuit(pWolf)
	pWolf.timerMove=pWolf.timerMove+dt
	if pWolf.timerMove>0.5 then
		pWolf.timerMove=0
		local bf=PFAStar(pWolf.l,pWolf.c,player.l,player.c,worldMap.currentMap.cell)
		if bf~=nil then
			local line=bf[#bf-1].l-pWolf.l
			local col=bf[#bf-1].c-pWolf.c
			Wolf_Move(pWolf,line,col)
		end
	end

	if not IntersectRectPointAABB(pWolf.c-8,pWolf.l-8,pWolf.c+8,pWolf.l+8,player.c,player.l) then
		pWolf.timerMove=0
		pWolf.state="normal"
	end
end

function Wolf_Update()
	for i,v in ipairs(listWolf) do
		if v.state=="normal" then
			Wolf_State_Normal(v)
		elseif v.state=="pursuit" then
			Wolf_State_Pursuit(v)
		end
	end
end

function Wolf_Draw()
	for i,v in ipairs(listWolf) do
		local x,y=Map_PosLineColToPx(worldMap.currentMap,v.c,v.l)
		local index=306
		if v.dir=="right" then
			index=306
		elseif v.dir=="left" then
			index=307
		elseif v.dir=="down" then
			index=308
		elseif v.dir=="up" then
			index=309
		end
		spr(index,x+scSh.x,y+scSh.y,0)
	end
end

function Bandit_Create(pLine,pCol)
	local newBandit={
		l=pLine,c=pCol,dir="right",state="normal",timerMove=0,
		durationMove=rnd(100,200)/100,timerShot=0,durationShot=rnd(40,60)/100,
		recul=false
	}
	table.insert(listBandit,newBandit)
end

function Bandit_Move(pBandit,pAmountLine,pAmountCol)
	local oldLine,oldCol=pBandit.l,pBandit.c
	pBandit.l=pBandit.l+pAmountLine
	pBandit.c=pBandit.c+pAmountCol
	if pAmountCol>0 then
		pBandit.dir="right"
	elseif pAmountLine>0 then
		pBandit.dir="down"
	elseif pAmountCol<0 then
		pBandit.dir="left"
	elseif pAmountLine<0 then
		pBandit.dir="up"
	end

	if Bandit_IntersectElement(pBandit)==-1 then
		pBandit.l=oldLine
		pBandit.c=oldCol
		return
	end

	Map_SetIndex(worldMap.currentMap,oldLine,oldCol,0)
	Map_SetIndex(worldMap.currentMap,pBandit.l,pBandit.c,INDEXMAP.bandit)
	Paricle_Emitter_Walk(pBandit.l,pBandit.c,pBandit.dir)
end

function Bandit_Shot(pBandit)
	pBandit.recul=true
	Bullet_Create(pBandit.l,pBandit.c,pBandit.dir,"bandit")
	Paricle_Emitter_Shot(pBandit.l,pBandit.c,pBandit.dir)
end

function Bandit_IntersectElement(pBandit)
	local index=Map_GetIndex(worldMap.currentMap,pBandit.l,pBandit.c)
	if index==-1 then return -1 end
	if index==INDEXMAP.food then
		return -1
	elseif index==INDEXMAP.obstacle then
		return -1
	elseif index==INDEXMAP.fuelCan then
		return -1
	elseif index==INDEXMAP.ammoBag then
		return -1
	elseif index==INDEXMAP.bandage then
		return -1
	elseif index==INDEXMAP.shelter then
		return -1
	elseif index==INDEXMAP.keyShelter then
		return -1
	elseif index==INDEXMAP.wolf then
		return -1
	elseif index==INDEXMAP.bandit then
		return -1
	elseif index==INDEXMAP.player then
		ScreenShake_Activate(0.3)
		Player_SetLife(-10)
		Paricle_Emitter_Blood(player.l,player.c,pBandit.dir)
		sfx(6)
		return -1
	end
	return 0
end

function Bandit_DetectionElement(pBandit,pRayonLong,pRayonLarg,pElementC,pElementL)
	local minX,minY,maxX,maxY=0,0,0,0
	if pBandit.dir=="right" then
		minX=pBandit.c
		minY=pBandit.l-pRayonLarg
		maxX=pBandit.c+pRayonLong
		maxY=pBandit.l+pRayonLarg
	elseif pBandit.dir=="left" then
		minX=pBandit.c-pRayonLong
		minY=pBandit.l-pRayonLarg
		maxX=pBandit.c
		maxY=pBandit.l+pRayonLarg
	elseif pBandit.dir=="down" then
		minX=pBandit.c-pRayonLarg
		minY=pBandit.l
		maxX=pBandit.c+pRayonLarg
		maxY=pBandit.l+pRayonLong
	elseif pBandit.dir=="up" then
		minX=pBandit.c-pRayonLarg
		minY=pBandit.l-pRayonLong
		maxX=pBandit.c+pRayonLarg
		maxY=pBandit.l
	end
	return IntersectRectPointAABB(minX,minY,maxX,maxY,pElementC,pElementL)
end

function Bandit_DetectionAttack(pBandit)
	if pBandit.dir=="right" then
		return pBandit.l==player.l
	elseif pBandit.dir=="left" then
		return pBandit.l==player.l
	elseif pBandit.dir=="down" then
		return pBandit.c==player.c
	elseif pBandit.dir=="up" then
		return pBandit.c==player.c
	end
	return false
end

function Bandit_State_Normal(pBandit)
	pBandit.timerMove=pBandit.timerMove+dt
	if pBandit.timerMove>pBandit.durationMove then
		pBandit.timerMove=0
		pBandit.durationMove=rnd(100,200)/100
		local rndDir=rnd(1,4)
		if rndDir==1 then
			Bandit_Move(pBandit,0,1)
		elseif rndDir==2 then
			Bandit_Move(pBandit,1,0)
		elseif rndDir==3 then
			Bandit_Move(pBandit,0,-1)
		elseif rndDir==4 then
			Bandit_Move(pBandit,-1,0)
		end
	end

	if Bandit_DetectionElement(pBandit,8,2,player.c,player.l) then
		pBandit.timerMove=0
		pBandit.state="pursuit"
	end
end

function Bandit_State_Pursuit(pBandit)
	pBandit.timerMove=pBandit.timerMove+dt
	if pBandit.timerMove>0.5 then
		pBandit.timerMove=0
		local bf=PFAStar(pBandit.l,pBandit.c,player.l,player.c,worldMap.currentMap.cell)
		if bf~=nil then
			local line=bf[#bf-1].l-pBandit.l
			local col=bf[#bf-1].c-pBandit.c
			Bandit_Move(pBandit,line,col)
		end
	end

	if Bandit_DetectionAttack(pBandit) then
		pBandit.timerMove=0
		Bandit_Shot(pBandit)
		pBandit.state="attack"
	end

	if not Bandit_DetectionElement(pBandit,12,8,player.c,player.l) then
		pBandit.timerMove=0
		pBandit.state="normal"
	end
end

function Bandit_State_Attack(pBandit)
	pBandit.timerShot=pBandit.timerShot+dt
	if pBandit.timerShot>pBandit.durationShot then
		pBandit.timerShot=0
		pBandit.durationShot=rnd(25,50)/100
		Bandit_Shot(pBandit)
	end

	if not Bandit_DetectionAttack(pBandit) then
		pBandit.timerShot=0
		pBandit.state="pursuit"
	end
end

function Bandit_Update()
	for i,v in ipairs(listBandit) do
		if v.state=="normal" then
			Bandit_State_Normal(v)
		elseif v.state=="pursuit" then
			Bandit_State_Pursuit(v)
		elseif v.state=="attack" then
			v.recul=false
			Bandit_State_Attack(v)
		end
	end
end

function Bandit_Draw()
	for i,v in ipairs(listBandit) do
		local x,y=Map_PosLineColToPx(worldMap.currentMap,v.c,v.l)
		local rx,ry=0,0
		local index=289
		if v.dir=="right" then
			index=290
			if v.recul then rx=-1 end
		elseif v.dir=="left" then
			index=291
			if v.recul then rx=1 end
		elseif v.dir=="down" then
			index=292
			if v.recul then ry=-1 end
		elseif v.dir=="up" then
			index=293
			if v.recul then ry=1 end
		end
		spr(index,x+rx+scSh.x,y+ry+scSh.y,0)
	end
end

function IntersectPlayerFood()
	for i=#listFood,1,-1 do
		local food=listFood[i]
		if player.l==food.l and player.c==food.c then
			Player_SetHunger(food.amount)
			table.remove(listFood,i)
		end
	end
end

function IntersectPlayerFuelCan()
	for i=#listFuelCan,1,-1 do
		local fuelCan=listFuelCan[i]
		if player.l==fuelCan.l and player.c==fuelCan.c then
			car.currentFuel=car.currentFuel+fuelCan.amount
			car.currentFuel=Clamp(car.currentFuel,0,car.capacityFuelMax)
			table.remove(listFuelCan,i)
		end
	end
end

function IntersectPlayerAmmoBag()
	for i=#listAmmoBag,1,-1 do
		local ammoBag=listAmmoBag[i]
		if player.l==ammoBag.l and player.c==ammoBag.c then
			Player_SetAmmo(ammoBag.amount)
			table.remove(listAmmoBag,i)
		end
	end
end

function IntersectPlayerBandage()
	for i=#listBandage,1,-1 do
		local bandage=listBandage[i]
		if player.l==bandage.l and player.c==bandage.c then
			Player_SetLife(bandage.amount)
			table.remove(listBandage,i)
		end
	end
end

function IntersectPlayerCarTool()
	for i=#listCarTool,1,-1 do
		local carTool=listCarTool[i]
		if player.l==carTool.l and player.c==carTool.c then
			car.currentDamage=car.currentDamage+carTool.amount
			car.currentDamage=Clamp(car.currentDamage,0,100)
			table.remove(listCarTool,i)
		end
	end
end

function IntersectPlayerShelter()
	for i=#listShelter,1,-1 do
		local shelter=listShelter[i]
		if player.l==shelter.l and player.c==shelter.c
			and not shelter.isLock then
			SwitchScene("victory")
		end
	end
end

function IntersectPlayerKeyShelter()
	for i=#listKeyShelter,1,-1 do
		local keyShelter=listKeyShelter[i]
		if player.l==keyShelter.l and player.c==keyShelter.c then
			for j=1,#listShelter do
				local shelter=listShelter[j]
				shelter.isLock=false
			end
			table.remove(listKeyShelter,i)
		end
	end
end

function IntersectBulletObstacle(pBullet)
	for i=1,#listObstacle do
		local obstacle=listObstacle[i]
		if pBullet.l==obstacle.l and pBullet.c==obstacle.c then
			return true
		end
	end
	return false
end

function IntersectBulletWolf(pBullet)
	for i=#listWolf,1,-1 do
		local wolf=listWolf[i]
		if pBullet.l==wolf.l and pBullet.c==wolf.c then
			Map_SetIndex(worldMap.currentMap,wolf.l,wolf.c,0)
			Paricle_Emitter_Blood(wolf.l,wolf.c,pBullet.dir)
			local rndDrop=rnd(0,100)
			if rndDrop<=30 then
				Food_Create(wolf.l,wolf.c)
				Map_SetIndex(worldMap.currentMap,wolf.l,wolf.c,INDEXMAP.food)
			end
			table.remove(listWolf,i)
			return true
		end
	end
	return false
end

function IntersectBulletBandit(pBullet)
	for i=1,#listBandit do
		local bandit=listBandit[i]
		if pBullet.l==bandit.l and pBullet.c==bandit.c then
			Map_SetIndex(worldMap.currentMap,bandit.l,bandit.c,0)
			Paricle_Emitter_Blood(bandit.l,bandit.c,pBullet.dir)
			local rndDrop=rnd(0,100)
			if rndDrop<=25 then
				Bandage_Create(bandit.l,bandit.c)
				Map_SetIndex(worldMap.currentMap,bandit.l,bandit.c,INDEXMAP.bandage)
			elseif rndDrop>25 and rndDrop<=50 then
				AmmoBag_Create(bandit.l,bandit.c)
				Map_SetIndex(worldMap.currentMap,bandit.l,bandit.c,INDEXMAP.ammoBag)
			elseif rndDrop>50 and rndDrop<=65 then
				CarTool_Create(bandit.l,bandit.c)
				Map_SetIndex(worldMap.currentMap,bandit.l,bandit.c,INDEXMAP.carTool)
			end
			table.remove(listBandit,i)
			return true
		end
	end
	return false
end

function Car_SetCurrentFuel(pAmount)
	car.currentFuel=car.currentFuel+pAmount
	car.currentFuel=Clamp(car.currentFuel,0,car.capacityFuelMax)
end

function Car_SetCurrentDamage(pAmount)
	car.currentDamage=car.currentDamage+pAmount
	car.currentDamage=Clamp(car.currentDamage,0,100)
end

function Car_LoadMap()
	car.x=-SIZESPR*2
	car.y=SIZESPR+1
	phaseAnimMoveCar="move"
end

function Car_Init()
	Car_LoadMap()
	car.currentFuel=50
	car.capacityFuelMax=100
	car.currentDamage=100
end


function Car_SetMove(pNumMove)
	if pNumMove==1 then
		phaseAnimMoveCar="move"
	elseif pNumMove==2 then phaseAnimMoveCar="move2"
	end
	sfx(10)
end

function Car_Update()
	if phaseAnimMoveCar=="move" then
		car.x=car.x+dt*60
		Paricle_Emitter_CarMove()
		if car.x>=worldMap.currentMap.offSet.x+safetyZone.c*(SIZESPR-1) then
			sfx(63)
			phaseAnimMoveCar="stop"
		end
	elseif phaseAnimMoveCar=="move2" then
		car.x=car.x+dt*60
		Paricle_Emitter_CarMove()
		if car.x>=SCREEN.w then
			SwitchScene("worldmap")
			--sfx(63)
		end
	end
	if car.currentDamage<100 then
		Paricle_Emitter_CarFlame()
	end
end

function Car_Draw()
	spr(317,car.x+scSh.x,car.y+scSh.y,0,1,0,0,2,1,0)
end

function Car_DrawGUI()
	local barreW=10
	local barreH=5
	local x=car.x-SIZESPR*3.5+scSh.x
	local y=car.y-SIZESPR+scSh.y
	local text=car.currentFuel.."/"..car.capacityFuelMax
	rect(x,y,car.currentFuel*barreW/car.capacityFuelMax,barreH,COLORID.YELLOW)
	rectb(x,y,barreW,barreH,COLORID.WHITE)
	x=x+barreW+1
	print(text,x,y,COLORID.WHITE)
	x=x+#text*SIZEFONT+4
	rect(x,y,car.currentDamage*barreW/100,barreH,COLORID.GRAY2)
	rectb(x,y,barreW,barreH,COLORID.WHITE)
	x=x+barreW+1
	print(car.currentDamage.."%",x,y,COLORID.WHITE)
end

function Car_Anim_SceneWorldMap_Init()
	car.x=(worldMap.numMap-0.5)*SCREEN.w/worldMap.nbMap-SIZESPR
	car.y=SCREEN.h-SIZESPR/2-32
	car.beginFuel=car.currentFuel
	car.endFuel=car.beginFuel-worldMap.currentMap.costFuelNextMap
	car.endFuel=Clamp(car.endFuel,0,car.capacityFuelMax)

	local rndRiskDamage=rnd(0,100)
	carAnimObstacleInRoad=false
	if rndRiskDamage<worldMap.currentMap.riskDamageCar then
		carAnimObstacleInRoad=true
	end

	sfx(10)
end

function Car_Anim_SceneWorldMap_Update()
	local endMove=(worldMap.numMap+0.5)*SCREEN.w/worldMap.nbMap-SIZESPR
	if car.x>=endMove then car.x=endMove end
	if carAnimObstacleInRoad then
		if car.x>=(worldMap.numMap)*SCREEN.w/worldMap.nbMap-SIZESPR*2 then
			Car_SetCurrentDamage(-worldMap.currentMap.costDamageCar)
			ScreenShake_Activate(0.2)
			HitStop_Activate(0.1)
			carAnimObstacleInRoad=false
		end
	end
	local pct=car.x/endMove
	car.currentFuel=flr(Lerp(car.beginFuel,car.endFuel,pct))
	car.currentFuel=Clamp(car.currentFuel,0,car.capacityFuelMax)
	if car.currentFuel<=0 or car.currentDamage<=0 then
		sfx(63)
		timerPauseCarAnim=timerPauseCarAnim+dt
		if timerPauseCarAnim>=1 then
			timerPauseCarAnim=0
			SwitchScene("gameover")
		end
	else
		if car.x>=endMove then
			sfx(63)
			car.x=endMove
			timerPauseCarAnim=timerPauseCarAnim+dt
			if timerPauseCarAnim>=1 then
				timerPauseCarAnim=0
				SwitchScene("gameplay")
				--WorldMap_CheckNextCurrentMap()
			end
		else
			car.x=car.x+dt*30
			Paricle_Emitter_CarMove()
		end
	end
	if car.currentDamage<=100 then
		Paricle_Emitter_CarFlame()
	end
end

function Car_Anim_SceneWorldMap_Draw()
	Car_Draw()

	if carAnimObstacleInRoad then
		spr(287,(worldMap.numMap)*SCREEN.w/worldMap.nbMap-SIZESPR/2,SCREEN.h-SIZESPR/2-32,0)
	end
end

function Car_Anim_SceneWorldMap_DrawGUI()
	local barreW=10
	local barreH=5
	local text=car.currentFuel.."/"..car.capacityFuelMax
	local w=barreW+#text*SIZEFONT+2
	local x=car.x+SIZESPR-w/2+scSh.x
	local y=car.y-SIZESPR-barreH+scSh.y
	rect(x,y,car.currentFuel*barreW/car.capacityFuelMax,barreH,COLORID.YELLOW)
	rectb(x,y,barreW,barreH,COLORID.WHITE)
	x=x+barreW+2
	print(text,x,y,COLORID.WHITE)

	text=car.currentDamage.."%"
	w=barreW+#text*SIZEFONT+2
	x=car.x+SIZESPR-w/2+scSh.x
	y=y+barreH+1
	rect(x,y,car.currentDamage*barreW/100,barreH,COLORID.GRAY2)
	rectb(x,y,barreW,barreH,COLORID.WHITE)
	x=x+barreW+2
	print(text,x,y,COLORID.WHITE)
end

function SafetyZone_Init()
	safetyZone.l=1
	safetyZone.c=flr(worldMap.currentMap.col/2+1)
end

function SafetyZone_Draw()
	if worldMap.numMap<worldMap.nbMap then
		local x,y=Map_PosLineColToPx(worldMap.currentMap,safetyZone.c,safetyZone.l)
		spr(333,x+scSh.x,y+scSh.y,0)
	end
end

function TimerAtomicBomb_Init()
	timerAtomicBomb.min.d=0
	timerAtomicBomb.min.u=2
	timerAtomicBomb.sec.d=0
	timerAtomicBomb.sec.u=0
	timerAtomicBomb.timer=0
	timerAtomicBomb.activateMusic=false
end

function TimerAtomicBomb_Update()
	if (timerAtomicBomb.sec.u==0 and timerAtomicBomb.sec.d==3) or
		(timerAtomicBomb.sec.u==0 and timerAtomicBomb.sec.d==0) then
		ScreenShake_ActivatePro(0.1,-1,1,-1,1)
	end
	if (timerAtomicBomb.min.u<=0 and timerAtomicBomb.min.d<=0 and
		timerAtomicBomb.sec.d<2) then
		ScreenShake_ActivatePro(0.1,-2,2,-2,2)
		if not timerAtomicBomb.activateMusic then
			music(0,-1,-1,true)
			timerAtomicBomb.activateMusic=true
		end
	end

	if timerAtomicBomb.min.u<=0 and timerAtomicBomb.min.d<=0 and
	timerAtomicBomb.sec.u<=0 and timerAtomicBomb.sec.d<=0 then
		SwitchScene("gameover")
		return
	end
	
	timerAtomicBomb.timer=timerAtomicBomb.timer+dt
	if timerAtomicBomb.timer>1  then
		timerAtomicBomb.timer=0
		timerAtomicBomb.sec.u=timerAtomicBomb.sec.u-1
		if timerAtomicBomb.sec.u<0 then
			sfx(3)
			timerAtomicBomb.sec.u=9
			timerAtomicBomb.sec.d=timerAtomicBomb.sec.d-1
		end
		if timerAtomicBomb.sec.d<0 then
			timerAtomicBomb.sec.d=5
			timerAtomicBomb.min.u=timerAtomicBomb.min.u-1
		end
	end
end

function TimerAtomicBomb_DrawGUI(pOffSetX,pOffSetY,pScale)
	local y=pOffSetY+scSh.y
	local scale=pScale
	local x=pOffSetX+scSh.x
	spr(48,x,y,0,scale,0,0,5,5)
	spr(1+timerAtomicBomb.min.d,x,y+SIZESPR*2*scale,0,scale)
	x=x+SIZESPR*scale
	spr(1+timerAtomicBomb.min.u,x,y+SIZESPR*2*scale,0,scale)
	x=x+SIZESPR*scale
	spr(11,x,y+SIZESPR*2*scale,0,scale)
	x=x+SIZESPR*scale
	spr(1+timerAtomicBomb.sec.d,x,y+SIZESPR*2*scale,0,scale)
	x=x+SIZESPR*scale
	spr(1+timerAtomicBomb.sec.u,x,y+SIZESPR*2*scale,0,scale)
end

function Score_Init()
	score=0
	compteur.food=0
	compteur.fuelCan=0
	compteur.ammoBag=0
	compteur.wolf=0
	compteur.bandit=0
end

function Score_Add(pAmount)
	score=score+flr(pAmount)
end

function Score_Draw()
	local y=SCREEN.h/2+16+scSh.y
	print("Score",1+scSh.x,y,COLORID.WHITE)
	y=y+8
	print(score,1+scSh.x,y,COLORID.WHITE)
end

function Score_Recap_Calcul()
	Score_Add(car.currentFuel*2)
	Score_Add(player.ammo*1)
	Score_Add(player.life*10)
	Score_Add(flr(player.hunger)*5)
end

function Score_Recap_Draw()
	local x,y=1,32
	spr(289,x,y,0)
	print("x"..compteur.bandit.." x40",x+SIZESPR+2,y+2,COLORID.WHITE)
	y=y+SIZESPR+1
	spr(306,x,y,0)
	print("x"..compteur.wolf.." x20",x+SIZESPR+2,y+2,COLORID.WHITE)
	y=y+SIZESPR+1
	spr(260,x,y,0)
	print("x"..compteur.food.." x100",x+SIZESPR+2,y+2,COLORID.WHITE)
	y=y+SIZESPR+1
	spr(263,x,y,0)
	print("x"..compteur.ammoBag.." x10",x+SIZESPR+2,y+2,COLORID.WHITE)
	y=y+SIZESPR+1
	spr(258,x,y,0)
	print("x"..compteur.fuelCan.." x50",x+SIZESPR+2,y+2,COLORID.WHITE)

	y=y+SIZESPR+1
	spr(334,x,y,0)
	print("x"..player.life.." x10",x+SIZESPR+2,y+2,COLORID.WHITE)
	y=y+SIZESPR+1
	spr(262,x,y,0)
	print("x"..flr(player.hunger).." x5",x+SIZESPR+2,y+2,COLORID.WHITE)
	y=y+SIZESPR+1
	spr(349,x,y,0)
	print("x"..car.currentFuel.." x2",x+SIZESPR+2,y+2,COLORID.WHITE)
	y=y+SIZESPR+1
	spr(350,x,y,0)
	print("x"..player.ammo.." x1",x+SIZESPR+2,y+2,COLORID.WHITE)

	TimerAtomicBomb_DrawGUI(SCREEN.w-SIZESPR*10-1,(SCREEN.h-SIZESPR*10)/2+SIZESPR,2)

	y=y+SIZESPR+2
	print("Score: "..score,1,y,COLORID.WHITE,false,2)
end

function DisplayScore_Create(pX,pY,pAmount,pColor)
	local newDisScore={
		x=pX,y=pY,amount=pAmount,timer=1,color=pColor
	}
	table.insert(listDisplayScore,newDisScore)
end

function DisplayScore_Update()
	for i=#listDisplayScore,1,-1 do
		local disScore=listDisplayScore[i]
		disScore.timer=disScore.timer-dt
		disScore.y=disScore.y-dt*20
		if disScore.timer<0 then
			table.remove(listDisplayScore,i)
		end
	end
end

function DisplayScore_Draw()
	for i,v in ipairs(listDisplayScore) do
		local text="+"..v.amount
		print(text,v.x-(#text*SIZEFONT)/2,v.y,v.color)
	end
end

function DisplayScore_PosLineColToPx_Create(pLine,pCol,pAmount,pColor)
	local x,y=Map_PosLineColToPx(worldMap.currentMap,pCol,pLine)
	DisplayScore_Create(x+SIZESPR/2,y,pAmount,pColor)
	Score_Add(pAmount)
end

function Game_LoadMap()
	listFood={}
	listObstacle={}
	listFuelCan={}
	listAmmoBag={}
	listShelter={}
	listKeyShelter={}
	listWolf={}
	listBandit={}
	listBandage={}
	listCarTool={}
	listParticle={}
	listDisplayScore={}

	SafetyZone_Init()
	Player_LoadMap()
	Car_LoadMap()

	local map=worldMap.currentMap
	for l=1,map.line do
		for c=1,map.col do
			local index=map.cell[l][c]
			if index==INDEXMAP.food then
				Food_Create(l,c)
			elseif index==INDEXMAP.fuelCan then
				FuelCan_Create(l,c)
			elseif index==INDEXMAP.ammoBag then
				AmmoBag_Create(l,c)
			elseif index==INDEXMAP.obstacle then
				Obstacle_Create(l,c)
			elseif index==INDEXMAP.carTool then
				CarTool_Create(l,c)
			elseif index==INDEXMAP.shelter then
				Shelter_Create(l,c)
			elseif index==INDEXMAP.keyShelter then
				KeyShelter_Create(l,c)
			elseif index==INDEXMAP.wolf then
				Wolf_Create(l,c)
			elseif index==INDEXMAP.bandit then
				Bandit_Create(l,c)
			end
		end
	end
end

function Game_Generate()
	WorldMap_Generate()
	Game_LoadMap()
	Car_Init()
	Player_Init()
	TimerAtomicBomb_Init()
	Score_Init()
end

function TIC()
	-- time --
	fTime.current=time()
	dt=(fTime.current-fTime.last)/1000
	fTime.last=fTime.current
	---------
	-- btn state --
	btnState.isDown.up=btn(BTNID.up)
	btnState.isDown.down=btn(BTNID.down)
	btnState.isDown.left=btn(BTNID.left)
	btnState.isDown.right=btn(BTNID.right)

	btnState.isReleased.up=false
	btnState.isReleased.down=false
	btnState.isReleased.left=false
	btnState.isReleased.right=false

	if not btnState.isDown.up and btnState.oldIsDown.up then btnState.isReleased.up=true end
	if not btnState.isDown.down and btnState.oldIsDown.down then btnState.isReleased.down=true end
	if not btnState.isDown.left and btnState.oldIsDown.left then btnState.isReleased.left=true end
	if not btnState.isDown.right and btnState.oldIsDown.right then btnState.isReleased.right=true end

	btnState.oldIsDown.up=btnState.isDown.up
	btnState.oldIsDown.down=btnState.isDown.down
	btnState.oldIsDown.left=btnState.isDown.left
	btnState.oldIsDown.right=btnState.isDown.right
	---------------
	if HitStop_Update() then return end
	ScreenShake_Update()
	UpdateScene()

	cls(0)
	DrawScene()

	-- if key(28) then
	-- 	print((time()-fTime.current),0,0,COLORID.WHITE)
	-- 	print(1000/dt,0,8,COLORID.WHITE)
	-- end
end

function SceneMenu_Start()
	music(1)
end

function SceneMenu_End() end

function SceneMenu_Update()
	if btnp(BTNID.a) then
		SwitchScene("gameplay")
	end
end

function SceneMenu_Draw()
	local transitionX=GetValueTransitionScene("menu","allX")
	local x=SCREEN.w/2+transitionX
	local y=SCREEN.h/2
	local scale=4
	spr(53,x-(SIZESPR*5*scale)/2,y-(SIZESPR*5*scale)/2,0,scale,0,0,5,5)
	rect(x-80,y-20,160,40,COLORID.GRAY3)
	rectb(x-80,y-20,160,40,COLORID.RED2)
	local text="Escape"
	print(text,x-(#text*SIZEFONT*2)/2,y-(SIZEFONT*5)/2,COLORID.WHITE,false,2)
	text="Apocalyp-Tic"
	print(text,x-(#text*SIZEFONT*2)/2,y,COLORID.WHITE,false,2)
	text="Press [A] to Start"
	rect(x-60,SCREEN.h-SIZEFONT*4-2,120,10,COLORID.GRAY3)
	rectb(x-60,SCREEN.h-SIZEFONT*4-2,120,10,COLORID.RED2)
	print(text,x-(#text*SIZEFONT)/2,SCREEN.h-SIZEFONT*4,COLORID.WHITE)
	print("by Yoghal",1+transitionX,SCREEN.h-SIZEFONT,COLORID.WHITE)
end

function SceneWorldMap_Start()
	sfx(63)
	Car_Anim_SceneWorldMap_Init()
	listParticle={}
end

function SceneWorldMap_End()
	WorldMap_NextCurrentMap()
	listParticle={}
end

function SceneWorldMap_Update()
	Car_Anim_SceneWorldMap_Update()
	Particle_Update()
end

function SceneWorldMap_Draw()
	local transitionX=GetValueTransitionScene("worldmap","allX")
	Car_Anim_SceneWorldMap_Draw()
	Particle_Draw()
	TimerAtomicBomb_DrawGUI((SCREEN.w-SIZESPR*10)/2,1,2)
	WorldMap_SceneWorldMap_DrawGUI()
	Car_Anim_SceneWorldMap_DrawGUI()
	rect(transitionX,0,SCREEN.w,SCREEN.h,0)
end

function SceneGameplay_Start()
	ScreenShake_Init()
	Car_SetMove(1)
end

function SceneGameplay_End() end

function SceneGameplay_Update()
	DisplayScore_Update()
	Car_Update()

	if phaseAnimMoveCar=="stop" then
		Bullet_Update()
		Player_Update()
		Bandit_Update()
		Wolf_Update()
		TimerAtomicBomb_Update()
	end

	Particle_Update()
end

function SceneGameplay_Draw()
	local transitionX=GetValueTransitionScene("gameplay","allX")
	Map_Draw()
	Shelter_Draw()
	KeyShelter_Draw()
	if phaseAnimMoveCar=="stop" then Player_Draw() end
	Food_Draw()
	Obstacle_Draw()
	FuelCan_Draw()
	AmmoBag_Draw()
	Bullet_Draw()
	Car_Draw()
	Bandage_Draw()
	CarTool_Draw()
	Bandit_Draw()
	Wolf_Draw()
	Particle_Draw()
	DisplayScore_Draw()

	if phaseAnimMoveCar=="stop" then
		Player_DrawGUI()
		Car_DrawGUI()
		WorldMap_DrawGUI()
	end

	TimerAtomicBomb_DrawGUI(1,SIZESPR*4,1)
	Score_Draw()
	rect(transitionX,0,SCREEN.w,SCREEN.h,0)
end

function SceneVictory_Start()
	Score_Recap_Calcul()
	ScreenShake_Init()
	music()
	sfx(63)
	music(2)
end

function SceneVictory_End()
	Game_Generate()
	music(1)
end

function SceneVictory_Update()
	if btnp(BTNID.a) then
		SwitchScene("gameplay")
	end
end

function SceneVictory_Draw()
	local transitionX=GetValueTransitionScene("victory","allX")
	local text="Victory"
	local y=1
	print(text,(SCREEN.w-#text*SIZEFONT*4)/2,y,COLORID.WHITE,false,4)
	text="You survived the apocalypse"
	y=y+24
	print(text,(SCREEN.w-#text*SIZEFONT)/2,y,COLORID.WHITE,false,1)
	Score_Recap_Draw()
	text="Press [A] to Start"
	print(text,(SCREEN.w-#text*SIZEFONT)/2,SCREEN.h-SIZEFONT*1,COLORID.WHITE)

	rect(transitionX,0,SCREEN.w,SCREEN.h,0)
end

function SceneGameOver_Start()
	Score_Recap_Calcul()
	ScreenShake_Init()
	music()
	sfx(63)
	music(3)
end

function SceneGameOver_End()
	Game_Generate()
	music(1)
end

function SceneGameOver_Update()
	if btnp(BTNID.a) then
		SwitchScene("gameplay")
	end
end

function SceneGameOver_Draw()
	local transitionX=GetValueTransitionScene("gameover","allX")
	local text="Game Over"
	local y=1
	print(text,(SCREEN.w-#text*SIZEFONT*4)/2,y,COLORID.WHITE,false,4)
	text="You didn't survive the apocalypse"
	y=y+24
	print(text,(SCREEN.w-#text*SIZEFONT)/2,y,COLORID.WHITE)
	Score_Recap_Draw()
	text="Press [A] to Start"
	print(text,(SCREEN.w-#text*SIZEFONT)/2,SCREEN.h-SIZEFONT*1,COLORID.WHITE)
	rect(transitionX,0,SCREEN.w,SCREEN.h,0)
end

WorldMap_Create()

CreateScene("menu",SceneMenu_Update,SceneMenu_Draw,SceneMenu_Start,SceneMenu_End)
CreateScene("worldmap",SceneWorldMap_Update,SceneWorldMap_Draw,SceneWorldMap_Start,SceneWorldMap_End)
CreateScene("gameplay",SceneGameplay_Update,SceneGameplay_Draw,SceneGameplay_Start,SceneGameplay_End)
CreateScene("victory",SceneVictory_Update,SceneVictory_Draw,SceneVictory_Start,SceneVictory_End)
CreateScene("gameover",SceneGameOver_Update,SceneGameOver_Draw,SceneGameOver_Start,SceneGameOver_End)

local duration=1
SetTransitionSceneIn("menu",Tween_EaseOutSine,duration)
SetTransitionSceneOut("menu",Tween_EaseInSine,duration)
SetTransitionSceneIn("worldmap",Tween_EaseOutSine,duration)
SetTransitionSceneOut("worldmap",Tween_EaseInSine,duration)
SetTransitionSceneIn("gameplay",Tween_EaseOutSine,duration)
SetTransitionSceneOut("gameplay",Tween_EaseInSine,duration)
SetTransitionSceneIn("victory",Tween_EaseOutSine,duration)
SetTransitionSceneOut("victory",Tween_EaseInSine,duration)
SetTransitionSceneIn("gameover",Tween_EaseOutSine,duration)
SetTransitionSceneOut("gameover",Tween_EaseInSine,duration)

AddElementTransitionSceneOut("menu","gameplay","allX",0,-SCREEN.w)

AddElementTransitionSceneIn("gameplay","menu","allX",0,SCREEN.w)

AddElementTransitionSceneIn("gameplay","worldmap","allX",0,SCREEN.w)
AddElementTransitionSceneOut("gameplay","worldmap","allX",-SCREEN.w,0)

AddElementTransitionSceneIn("gameplay","victory","allX",0,SCREEN.w)
AddElementTransitionSceneIn("gameplay","gameover","allX",0,SCREEN.w)

AddElementTransitionSceneIn("worldmap","gameplay","allX",0,SCREEN.w)
AddElementTransitionSceneOut("worldmap","gameplay","allX",-SCREEN.w,0)
AddElementTransitionSceneOut("worldmap","gameover","allX",-SCREEN.w,0)

AddElementTransitionSceneIn("victory","gameplay","allX",0,SCREEN.w)
AddElementTransitionSceneOut("victory","gameplay","allX",-SCREEN.w,0)

AddElementTransitionSceneIn("gameover","worldmap","allX",0,SCREEN.w)
AddElementTransitionSceneIn("gameover","gameplay","allX",0,SCREEN.w)
AddElementTransitionSceneOut("gameover","gameplay","allX",-SCREEN.w,0)

SwitchScene("menu")

Game_Generate()

-- <TILES>
-- 001:0000000000022000002002000020020000000000002002000020020000022000
-- 002:0000000000000000000002000000020000000000000002000000020000000000
-- 003:0000000000022000000002000000020000022000002000000020000000022000
-- 004:0000000000022000000002000000020000022000000002000000020000022000
-- 005:0000000000000000002002000020020000022000000002000000020000000000
-- 006:0000000000022000002000000020000000022000000002000000020000022000
-- 007:0000000000022000002000000020000000022000002002000020020000022000
-- 008:0000000000022000000002000000020000000000000002000000020000000000
-- 009:0000000000022000002002000020020000022000002002000020020000022000
-- 010:0000000000022000002002000020020000022000000002000000020000022000
-- 011:0000000000000000000000000002000000000000000200000000000000000000
-- 016:eefffffeeeeffffefeeefeeeffeeeeddfffeedddffeeddddffedddddeeeddddd
-- 017:efffffeeeffffeeeeeefeeefddeeeeffdddeefffddddeeffdddddeffdddddeee
-- 018:00000044000044440004f444004fff4404ffff4404fffff44ffffff44fffff4f
-- 019:4400000044440000444f400044fff40044ffff404fffff404ffffff4f4fffff4
-- 020:ff44ff44f44ff44f44ff44ff4ff44ff4ff44ff44f44ff44f44ff44ff4ff44ff4
-- 021:44ff44fff44ff44fff44ff444ff44ff444ff44fff44ff44fff44ff444ff44ff4
-- 022:ffffffff44444444ffffffff44444444ffffffff44444444ffffffff44444444
-- 032:eeedddddffedddddffeeddddfffeedddffeeeedd777776557777655577765555
-- 033:dddddeeedddddeffddddeeffdddeefffddeeeeff556777775556777755556777
-- 034:4444444f444444440444444f044444ff004444ff00044fff000044ff00000044
-- 035:f444444444444444f4444440ff444440ff444400fff44000ff44000044000000
-- 036:4ff44ff444ff44fff44ff44fff44ff444ff44ff444ff44fff44ff44fff44ff44
-- 037:4ff44ff4ff44ff44f44ff44f44ff44ff4ff44ff4ff44ff44f44ff44f44ff44ff
-- 038:f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4
-- 048:00000000000000000000000000000000000000000000000f000000ff00000ff4
-- 049:0000000000000fff000fffff0ffff444fff44444f44f44444ffff444ffffff44
-- 050:ffffffffffffffff444444444444444444444444444444444444444444444444
-- 051:00000000fff00000fffff000444ffff044444fff4444f44f444ffff444ffffff
-- 052:0000000000000000000000000000000000000000f0000000ff0000004ff00000
-- 053:00000000000000000000000000000000000000000000000f000000ff00000ff4
-- 054:0000000000000fff000fffff0ffff444fff44444f44f44444ffff444ffffff44
-- 055:ffffffffffffffff444444444444444444444444444444444444444444444444
-- 056:00000000fff00000fffff000444ffff044444fff4444f44f444ffff444ffffff
-- 057:0000000000000000000000000000000000000000f0000000ff0000004ff00000
-- 064:0000ff4f000ff4ff000ff4ff00ff4fff00ff4fff0ff4ffff0ff4ffff22222222
-- 065:ffffff44fffffff4fffffff4ffffffffffffffffffffffffffffffff22222222
-- 066:4444444444444444444444444444444444444444f444444ff444444f22222222
-- 067:44ffffff4fffffff4fffffffffffffffffffffffffffffffffffffff22222222
-- 068:f4ff0000ff4ff000ff4ff000fff4ff00fff4ff00ffff4ff0ffff4ff022222222
-- 069:0000ff4f000ff4ff000ff4ff00ff4fff00ff4fff0ff4ffff0ff4ffff0ff4ffff
-- 070:ffffff44fffffff4fffffff4ffffffffffffffffffffffffffffffffffffffff
-- 071:4444444444444444444444444444444444444444f444444ff444444fff4444ff
-- 072:44ffffff4fffffff4fffffffffffffffffffffffffffffffffffffffffffffff
-- 073:f4ff0000ff4ff000ff4ff000fff4ff00fff4ff00ffff4ff0ffff4ff0ffff4ff0
-- 080:2fffffff2fffffff2fffffff2fffffff2fffffff2fffffff2fffffff2fffffff
-- 081:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 082:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 083:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 084:fffffff2fffffff2fffffff2fffffff2fffffff2fffffff2fffffff2fffffff2
-- 085:ff4fffffff4fffffff4fffffff44ffffff444444ff444444ff444444ff444444
-- 086:ffffffffffffffffffffffffffffffff44444444444444444444444444444444
-- 087:ff4444fff44ff44f44ffff444ffffff44ffffff444ffff44444ff4444f4444f4
-- 088:ffffffffffffffffffffffffffffffff44444444444444444444444444444444
-- 089:fffff4fffffff4fffffff4ffffff44ff444444ff444444ff444444ff444444ff
-- 096:2fffffff222222220ff4444400ff444400ff4444000ff444000ff4440000ff44
-- 097:ffffffff222222224444444f4444444f444444ff444444ff44444fff44444fff
-- 098:ffffffff22222222ffffffffffffffffffffffffffffffffffffffffffffffff
-- 099:ffffffff22222222f4444444f4444444ff444444ff444444fff44444fff44444
-- 100:fffffff22222222244444ff04444ff004444ff00444ff000444ff00044ff0000
-- 101:0ff444440ff444440ff4444400ff444400ff4444000ff444000ff4440000ff44
-- 102:44444444444444444444444f4444444f444444ff444444ff44444fff44444fff
-- 103:fff44fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 104:4444444444444444f4444444f4444444ff444444ff444444fff44444fff44444
-- 105:44444ff044444ff044444ff04444ff004444ff00444ff000444ff00044ff0000
-- 112:00000ff4000000ff0000000f0000000000000000000000000000000000000000
-- 113:4444ffff4444fffff444fffffff44fff0ffff444000fffff00000fff00000000
-- 114:ffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffff
-- 115:ffff4444ffff4444ffff444ffff44fff444ffff0fffff000fff0000000000000
-- 116:4ff00000ff000000f00000000000000000000000000000000000000000000000
-- 117:00000ff4000000ff0000000f0000000000000000000000000000000000000000
-- 118:4444ffff4444fffff444fffffff44fff0ffff444000fffff00000fff00000000
-- 119:ffffffffffffffffffffffffffffffffffffffff44444444ffffffffffffffff
-- 120:ffff4444ffff4444ffff444ffff44fff444ffff0fffff000fff0000000000000
-- 121:4ff00000ff000000f00000000000000000000000000000000000000000000000
-- </TILES>

-- <SPRITES>
-- 002:00000000022244400222240402e2e200022e2200022e220002e2e20002222200
-- 003:033330003333333333c2222233333333c3333ddcfdccdfeeefefeeee0efef000
-- 004:00000cc000000ccc0333cccc33333c0033333200323332002333220002222000
-- 005:0000000000000000033300002333300c23333ccc22233ddc2222200d02220000
-- 006:042200004222240042222224422c2c24422ccc24422222243333344403334440
-- 007:00000000000000000000000003030300f4f4f4f0f4f4f4f0f4f4f4f00fffff00
-- 008:00000d000000d0000000fd0d000fffd00dfff000d0df0000000d000000d00000
-- 013:0000000000000000000400000004000000030000000300000002000000000000
-- 014:0000000000000000000400000042300000423000004230000003000000000000
-- 015:0000000000000000000420000042220000423300004233000003300000000000
-- 017:0022220000222220004f4f000044440004222240042222400422224000f00f00
-- 018:022220000222220004f4f00004444000422220ee442224d0022220000f00f000
-- 019:0002222000222220000f4f40000444400002ee2400422d4400022220000f00f0
-- 020:0022220000222200004f4f0000444400042222400044e4000022e20000f00f00
-- 021:0022220000222200002222000044440004222240002222000022220000f00f00
-- 022:022220000222220004f4f0000444400042eeeeee44d224d0022220000f00f000
-- 023:000000000000000000000000000000000123ed00000000000000000000000000
-- 029:0066670006766670766776676766676666776676066676600002200000022000
-- 030:0006700000667700067767700066770006776670676677770677666000022000
-- 031:000000000000000000eee0000eefeee00efeefe0efefeeee0eefefee00eeee00
-- 033:0000000000777700074f4f000044440004777740047777400477774000f00f00
-- 034:000000000777700074f4f0000444400047eeeeee44d774d0077770000f00f000
-- 035:0000000000077770000f4f4700044440eeeeee740d477d4400077770000f00f0
-- 036:0000000000777700004f4f00004444000477e7400044e7400077e40000f0ef00
-- 037:0000e00000777700007777000044440004777740007777000077770000f00f00
-- 045:6666666666666666666666666666666666666666666666666666666666666666
-- 046:7777777777777777777777777777777777777777777777777777777777777777
-- 050:000e00e0000eedd0000efeff000eeeee000eeedddedeeee0eeeeede0e0e0e0e0
-- 051:0e00e0000ddee000ffefe000eeeee000ddeee0000eeeeded0edeeeee0e0e0e0e
-- 052:0000000000edde0000deed0000edde0000feef0000effe0000edde0000e00e00
-- 053:00e00e0000edde0000eeee0000deed0000edde0000deed0000edde0000e00e00
-- 061:000000000000088800008dd800008dd888888888888f888808fef888000f0000
-- 062:0000000088000000dd800000ddd80000888888808888f888888fef880000f000
-- 063:ff0ff0fffffeefff0feeeef0feeffeeffeeffeef0feeeef0fffeefffff0ff0ff
-- 077:3444444341122114412222144212212441122114411221144112211434444443
-- 078:00000000022022002cc222202c222c200222c200002220000002000000000000
-- 079:ee0ee0eeeee44eee0e4444e0e444444ee444444e0e4444e0eee44eeeee0ee0ee
-- 093:00000000000400000044400004cc440004c44400044444000044400000000000
-- 094:00000000000123ed00000000123ed0000000000000123ed0000000000123ed00
-- 095:00000000000000000ce00000c00e0000c00eddcce00e0d0d0ec0000000000000
-- 109:00200000022200200020022200000020020200002c2220000222000000200000
-- 110:0000333000032123003212130321212332121230312123003212300003330000
-- 111:00000c000c212dc0c2122dc000221dc000340c00003300000043000000340000
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- 004:0000000000000000ffffffffffffffff
-- </WAVES>

-- <SFX>
-- 000:00400080f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000300000000000
-- 001:000010101020203020403050306040704080409050a050b060c060d070e080f0805090609070a080a090b0a0b0b0c030c040d050d060e070e080f000400000000000
-- 002:03f003e013d013c023c023b023a043a043905390639063807380737083708370936093609350a350a340b340b340c330c330d330d320e310f300f300320000000000
-- 003:f000d020b0409060708050a030c010e000f000f000f000f000f000f000f000f000f000f000f000f000f000f010e030c050a070809060b040d020f000370000000000
-- 004:e000d000d000c020b030a0409050806070706080609050b040103030204020602080109010b000c000d010e010503070408060b090d0d000f000f000310000000000
-- 005:f010e020d030c040b050a0609060806070606050504040303010200010000010f020d030b04090507060508030a010c000f000d0009000600030f000410000000000
-- 006:00400020f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000170000000000
-- 007:f000d010b020a03090507060608040a020b010c000c020c050b090a0d080d060c050a040804060403040104000402040404070408030b020d010f000210000000000
-- 008:03f003f003e003d003d003c003c003b013b023a033a043905390639063807380837083709360a350b350c340c340d330e330f320f310f300f300f300310000000000
-- 009:03f003e0f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300320000000000
-- 010:d350937013b003d003a0a340e300a35053b003e003c013b0c370f320f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f3002700000f0f00
-- 011:00f00090f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000500000000000
-- 012:b040b040b040b04050905090509050905090509000f000f000f000f000f000f000f000f000f0f000f000f000f000f000f000f000f000f000f000f000410000000000
-- 013:03e023c043a063808360a340c320e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300300000000000
-- 016:0000100020003000400050006000700080009000a000b000c000d000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000500000000000
-- 017:0100110021003100410051006100710081009100a100b100c100d100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100f100400000000000
-- 018:0300130023003300430053006300730083009300a300b300c300d300e300f300f300f300f300f300f300f300f300f300f300f300f300f300f300f300503000000000
-- 020:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000406000000000
-- 021:020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200309000000000
-- 022:01000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010020b000000000
-- 024:00000000100010002000200030003000400040005000500060006000700070008000800090009000a000a000b000b000c000c000d000d000e000f000500000000000
-- 063:f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000000000000000
-- </SFX>

-- <PATTERNS>
-- 000:40000900000000003000000040000b00000000003000000040000900000000003000000040000b00000000003000000050000900000000003000000050000b00000000003000000050000900000000003000000050000b000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:40000900000040000b00000140000900000040000b00000050000900000150000b00000050000900000050000b00000140000900000040000b00000140000900000140000b00000050000900000050000b00000150000900000050000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:40000940000b40000940000b50000950000b50000950000b40000940000b40000940000b50000950000b50000950000b40000940000b40000940000b50000950000b50000950000b40000940000b40000940000b50000950000b50000950000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:800069500069800069500069800069500069800069500069800069500069800069500069800069500069800069500069000061000000000061000000000061000041000061000041000061000000000061000000000061000000000061000000600007000000000000000000000000000000000000000000400007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:700069400069700069400069700069400069700069400069700069400069700069400069700069400069700069400069100041000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:500069e00067500069e00067500069e00067500069e00067500069e00067500069e00067500069e00067500069e00067000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:400087000000000000000000000000000000000000000000000000000000400087000001400087000001400087000001600087000001000000000000000000000000000000000000000000000000600087000000600087000000600087000000800087000000000000000000000000000000000000000000000000000000800087000000800087000000800087000000a00087000000000000000000000000000000000000000000000000000000a00087000001800087000000a00087000000
-- 007:c00087000000000000000000000000000000000000000000000000000000c00087000000c00087000000c00087000000e00087000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400089000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000001000000000001000000000001000000
-- 010:a0001900000040001b000000a0001b000000000000000000a0001900000040001b000000a0001b000000000000000000a0001900000040001b000000a0001b000000000000000000a0001900000040001b000000a0001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:a0001940001ba0001b000000a0001940001ba0001b000000a0001940001ba0001b000000a0001940001ba0001b000000a0001940001ba0001b000000a0001940001ba0001b000000a0001940001ba0001b000000a0001940001ba0001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:a00019a0001ba00019a0001ba00019a0001ba00019a0001ba00019a0001ba00019a0001ba00019a0001ba00019a0001ba00019a0001ba00019a0001ba00019a0001ba00019a0001ba00019a0001ba00019a0001ba00019a0001ba00019a0001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:c00069000051000051000051c00069000051000051000051c00069000051000051000051c00069000051000051000000000051000051000051000051000051000051000051000051000051000051000051000051000051000051000051000051000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:b00069000000000000000000b00069000000000000000000b00069000000000000000000b00069000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:900069000000000000000000900069000000000000000000900069000000000000000000900069000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:800087000000000000000000000000000000000000000000000000000000800087000000800087000000800087000000a00087000000000000000000000000000000000000000000000000000000a00087000000a00087000000a00087000000c00087000000000000000000000000000000000000000000000000000000c00087000000c00087000000c00087000000e00087000000000000000000000000000000000000000000000000000000e00087000000c00087000000e00087000000
-- 017:400089000000000000000000000000000000000000000000000000000000400089000000400089000000400089000000600089000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800089000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:400025000000000030000000400027000000000030000000400025000000000030000000400027000000000030000000500025000000000030000000500027000000000030000000500025000000000030000000500027000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:400025000000400027000001400025000000400027000000500025000001500027000000500025000000500027000001400025000000400027000001400025000001400027000000500025000000500027000001500025000000500027000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 022:400025400027400025400027500025500027500025500027400025400027400025400027500025500027500025500027400025400027400025400027500025500027500025500027400025400027400025400027500025500027500025500027000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 023:000061000000000000c00067000000000000000000c00067000000000000000000c00067000000000000000000c00067000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 024:000061000000000000b00067000000000000000000b00067000000000000000000b00067000000000000000000b00067000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 025:000000000000000000900067000000000000000000900067000000000000000000900067000000000000000000900067000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 026:b00087000000000000000000000000000000000000000000000000000000b00087000000b00087000000b00087000000d00087000000000000000000000000000000000000000000000000000000d00087000000d00087000000d00087000000f00087000000000000000000000000000000000000000000000000000000f00087000000f00087000000f00087000000500089000000000000000000000000000000000000000000000000000000500089000000f00087000000500089000000
-- 027:700089000000000000000000000000000000000000000000000000000000700089000000700089000000700089000000900089000000000000000000000000000000000001900089000001000000700089000000000000900089000001000000b00089000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000
-- 030:400036000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:400036000000000000000000000000000000000000000000000000000000000000000000000030000000000000000000500036000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:400036000000000000000000000000000000000000000000500036000000000000000000000030000000000000000000400036000000000000000000000000000000000000000000500036000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:b00049100071000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:a00049100071000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:900049100071000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:800049100071000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:d00017000000c00017000000a00017000000800017000000000000000000000000000000000000000000500017000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:d00017000000c00017000000800017000000600017000000000000000000000000000000000000000000a00017000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:d00017000000c00017000000800017000000a00017000000000000000000000000000000000000000000a00017000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:500067000000000000000000000000000000000000000000d00065000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 051:600065000000000000000000000061000000000000000000900065000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </PATTERNS>

-- <TRACKS>
-- 000:1c25d71c25d7203618203618343758343758000000000000000000000000000000000000000000000000000000000000000200
-- 001:4838105c3910483810604a104838105c3910483810604a104838985c39d8483819604a594838985c39d8483819604a59ec0300
-- 002:744b10884c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:9ec000a2d0009ec000b2d0009ec000a2d0009ec000b2d0009ec000a2d0009ec000b2d000000000000000000000000000ab0300
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

