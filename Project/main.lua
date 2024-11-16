function newPlayer(x, y, hp, rd, spl, bt)
	local plr={
		X=x;
		Y=y;
		HP=hp;
		BaseHP=hp;
		RenderDistance=rd;
		CurrentSpell=spl;
		Bite=bt;
		Ailments={};
	}
	return plr
end

function NewEnemy(x, y, hp, dam, rng, sprt)
	local en={
		X=x;
		Y=y;
		HP=hp;
		BaseHP=hp;
		Damage=dam;
		Range=rng;
		SpriteString=sprt;
		Sprite=love.graphics.newImage(sprt);
		Ailments={}
	}
	return en
end

map={}
sprites={}
enemies={}

function love.load()
	NewGame()
	
	sprites[0]=love.graphics.newImage('Dirt15.png')
	sprites[-1]=love.graphics.newImage('StoneWall15.png')
	sprites[1]=love.graphics.newImage('Player15.png')
	sprites[2]=love.graphics.newImage('Cursor15.png')
	sprites[3]=love.graphics.newImage('PlayerOverlay.png')
	sprites[4]=love.graphics.newImage('Cursor30.png')
	sprites[5]=love.graphics.newImage('BleedText.png')
	sprites[6]=love.graphics.newImage('TransfusionText.png')
	sprites[7]=love.graphics.newImage('BlastText.png')
	sprites[8]=love.graphics.newImage('BiteText.png')
	sprites[9]=love.graphics.newImage('BleedDesc.png')
	sprites[10]=love.graphics.newImage('TransfusionDesc.png')
	sprites[11]=love.graphics.newImage('BlastDesc.png')
	sprites[12]=love.graphics.newImage('BiteDesc.png')
	sprites[13]=love.graphics.newImage('Stairs15.png')
	sprites[14]=love.graphics.newImage('BlackBar420x15.png')
	sprites[15]=love.graphics.newImage('EnemyOverlay.png')
	sprites[16]=love.graphics.newImage('BlackBar15x255.png')
	sprites[17]=love.graphics.newImage('Goblin135.png')
	sprites[18]=love.graphics.newImage('Skeleton135.png')
	
	love.window.setMode(600, 600, {resizable=false})
	love.keyboard.setKeyRepeat(false)
end

function love.update()
	
end

function love.keypressed(key)
	if key=='w' then
		if cursorY>1 and rendered[cursorY-1][cursorX]==1 then
			cursorY=cursorY-1
		end
	elseif key=='s' then
		if cursorY<#map and rendered[cursorY+1][cursorX]==1 then
			cursorY=cursorY+1
		end
	elseif key=='a' then
		if cursorX>1 and rendered[cursorY][cursorX-1]==1 then
			cursorX=cursorX-1
		end
	elseif key=='d' then
		if cursorX<#map and rendered[cursorY][cursorX+1]==1 then
			cursorX=cursorX+1
		end
	elseif key=='1' then
		player.CurrentSpell='Bleed'
	elseif key=='2' then
		player.CurrentSpell='Transfusion'
	elseif key=='3' then
		player.CurrentSpell='Vampiric Blast'
	elseif key=='4' then
		player.CurrentSpell='Vampire\'s Bite'
	elseif key=='e' then
		if player.HP==0 then
			NewGame()
		elseif player.X==stairsX and player.Y==stairsY then
			NewFloor()
		end
	elseif player.HP>0 then
		TakeTurn(key)
	end
end

function love.draw()
	RenderLOS()
	DrawEnemies()
	GetInfo()
	GameOver()
end

function Generate(posX, posY, steps, halls)
	for y=1, 30, 1 do
		map[y]={}
		for x=1, 30, 1 do
			map[y][x]=-1
		end
	end
	
	local dir=1
	map[posY][posX]=0
	for i=1, steps, 1 do
		dir=math.random(1, 4)
		for x=1, math.random(1, halls), 1 do
			if dir==1 and posX+1<#map-1 then
				posX=posX+1
			elseif dir==2 and posX-1>1 then
				posX=posX-1
			elseif dir==3 and posY+1<#map-1 then
				posY=posY+1
			elseif dir==4 and posY-1>1 then
				posY=posY-1
			end
			map[posY][posX]=0
		end
	end
end

function RenderLOS()
	rendered={}
	for y=1, #map, 1 do
		rendered[y]={}
		for x=1, #map, 1 do
			rendered[y][x]=0
		end
	end
	
	for scan=1, 360, 1 do
		local hit=0
		local rayDist=0
		local raySpeed=0.01
		local rayX=player.X+.5
		local rayY=player.Y+.5
		while hit==0 and rayDist<player.RenderDistance do
			rayX=rayX+(raySpeed*math.cos(math.rad(scan)))
			rayY=rayY+(raySpeed*math.sin(math.rad(scan)))
			
			rayDist=math.sqrt((rayX-(player.X+.5))^2+(rayY-(player.Y+.5))^2)
			
			rendered[math.floor(rayY)][math.floor(rayX)]=1
			
			if map[math.floor(rayY)][math.floor(rayX)]<0 then
				hit=1
			end
		end
	end
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(sprites[0], 0, 0, 0, #map, #map, 0, 0, 0, 0)
	for y=1, #map, 1 do
		for x=1, #map, 1 do
			if rendered[y][x]==0 then
				love.graphics.setColor(0, 0, 0)
				love.graphics.rectangle('fill', (x-1)*15, (y-1)*15, 15, 15)
			elseif map[y][x]<0 then
				love.graphics.setColor(255, 255, 255)
				love.graphics.draw(sprites[map[y][x]], (x-1)*15, (y-1)*15, 0, 1, 1, 0, 0, 0, 0)
			elseif stairsX==x and stairsY==y then
				love.graphics.setColor(255, 255, 255)
				love.graphics.draw(sprites[13], (x-1)*15, (y-1)*15, 0, 1, 1, 0, 0, 0, 0)
			end
		end
	end
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(sprites[1], (player.X-1)*15, (player.Y-1)*15, 0, 1, 1, 0, 0, 0, 0)
end

function MovePlayer(dx, dy)
	local combat=0
	if #enemies>0 then
		for i=1, #enemies, 1 do
			if enemies[i].X==player.X+dx and enemies[i].Y==player.Y+dy then
				CastSpell(i)
				combat=1
				turn=true
			end
		end
	end
	if combat==0 and player.Y+dy>1 and player.Y+dy<#map and player.X+dx>1 and player.X+dx<#map and map[player.Y+dy][player.X+dx]==0 then
		player.X=player.X+dx
		player.Y=player.Y+dy
		cursorX=player.X
		cursorY=player.Y
		if player.HP<player.BaseHP then 
			player.HP=player.HP+1
		end
		turn=true
	end
end

function GetInfo()
	love.graphics.draw(sprites[15], 435, 0, 0, 1, 1, 0, 0, 0, 0)
	love.graphics.print(player.HP, (player.X-1)*15, (player.Y-1)*15)
	if cursorX==player.X and cursorY==player.Y then
	else
		love.graphics.draw(sprites[2], (cursorX-1)*15, (cursorY-1)*15, 0, 1, 1, 0, 0, 0, 0)
		if #enemies>0 then
			for i=1, #enemies, 1 do
				if enemies[i].X==cursorX and enemies[i].Y==cursorY then
					if enemies[i].SpriteString=='Goblin15.png' then
						love.graphics.draw(sprites[17], 450, 15, 0, 1, 1, 0, 0, 0, 0)
						if enemies[i].HP<enemies[i].BaseHP then
							local amount=255-(enemies[i].HP/enemies[i].BaseHP*255)
							local enBar=love.graphics.newQuad(0, 0, 15, amount, 15, 255)
							love.graphics.draw(sprites[16], enBar, 450, 420-amount)
						end
					elseif enemies[i].SpriteString=='Skeleton15.png' then
						love.graphics.draw(sprites[18], 450, 15, 0, 1, 1, 0, 0, 0, 0)
						if enemies[i].HP<enemies[i].BaseHP then
							local amount=255-(enemies[i].HP/enemies[i].BaseHP*255)
							local enBar=love.graphics.newQuad(0, 0, 15, amount, 15, 255)
							love.graphics.draw(sprites[16], enBar, 450, 420-amount)
						end
					end
				end
			end
		end
	end
	love.graphics.draw(sprites[3], 0, 435, 0, 1, 1, 0, 0, 0, 0)
	if player.HP<player.BaseHP then
		local amount=420-(player.HP/player.BaseHP*420)
		local blackBar=love.graphics.newQuad(0, 0, amount, 15, 420, 15)
		love.graphics.draw(sprites[14], blackBar, 585-amount, 570)
	end
	
	if player.CurrentSpell=='Bleed' then
		love.graphics.draw(sprites[4], 165, 450, 0, 1, 1, 0, 0, 0, 0)
		love.graphics.draw(sprites[5], 287, 465, 0, 1, 1, 0, 0, 0, 0)
		love.graphics.draw(sprites[9], 165, 482, 0, 1, 1, 0, 0, 0, 0)
	elseif player.CurrentSpell=='Transfusion' then
		love.graphics.draw(sprites[4], 195, 450, 0, 1, 1, 0, 0, 0, 0)
		love.graphics.draw(sprites[6], 287, 465, 0, 1, 1, 0, 0, 0, 0)
		love.graphics.draw(sprites[10], 165, 482, 0, 1, 1, 0, 0, 0, 0)
	elseif player.CurrentSpell=='Vampiric Blast' then
		love.graphics.draw(sprites[4], 225, 450, 0, 1, 1, 0, 0, 0, 0)
		love.graphics.draw(sprites[7], 287, 465, 0, 1, 1, 0, 0, 0, 0)
		love.graphics.draw(sprites[11], 165, 482, 0, 1, 1, 0, 0, 0, 0)
	elseif player.CurrentSpell=='Vampire\'s Bite' then
		love.graphics.draw(sprites[4], 255, 450, 0, 1, 1, 0, 0, 0, 0)
		love.graphics.draw(sprites[8], 287, 465, 0, 1, 1, 0, 0, 0, 0)
		love.graphics.draw(sprites[12], 165, 482, 0, 1, 1, 0, 0, 0, 0)
	end
end

function DrawEnemies()
	if #enemies>0 then
		for i=1, #enemies, 1 do
			if rendered[enemies[i].Y][enemies[i].X]==1 then
				love.graphics.draw(enemies[i].Sprite, (enemies[i].X-1)*15, (enemies[i].Y-1)*15, 0, 1, 1, 0, 0, 0, 0)
				love.graphics.print(enemies[i].HP, (enemies[i].X-1)*15, (enemies[i].Y-1)*15)
			end
		end
	end
end

function TakeTurn(key)
	turn=false
	if key=='up' then
		MovePlayer(0, -1)
	elseif key=='down' then
		MovePlayer(0, 1)
	elseif key=='left' then
		MovePlayer(-1, 0)
	elseif key=='right' then
		MovePlayer(1, 0)
	elseif key==' ' then
		MovePlayer(0, 0)
		turn=true
	elseif key=='return' then
		if player.CurrentSpell~='Vampire\'s Bite' then
			if #enemies>0 then
				for i=1, #enemies, 1 do
					if enemies[i].X==cursorX and enemies[i].Y==cursorY then
						CastSpell(i)
						turn=true
						break
					end
				end
			end
		end
	end
	
	if turn==true then
		EnemyAttack()
		TickAilments()
		CheckHealth()
		EnemyMove()
	end
end

function CastSpell(target)
	if player.CurrentSpell=='Bleed' then
		local pAil=#player.Ailments+1
		player.Ailments[pAil]={}
		player.Ailments[pAil][1]=2 --damage
		player.Ailments[pAil][2]=3 --How many turns
		
		local enAil=#enemies[target].Ailments+1
		enemies[target].Ailments[enAil]={}
		enemies[target].Ailments[enAil][1]=3 --damage
		enemies[target].Ailments[enAil][2]=3 --How many turns
	
	elseif player.CurrentSpell=='Transfusion' then
		enemies[target].HP=enemies[target].HP+2
		player.HP=player.HP+1
	
	elseif player.CurrentSpell=='Vampiric Blast' then
		--local yourDam=enemies[target].HP
		--local enemyDam=player.HP
		player.HP=1
		enemies[target].HP=1
	elseif player.CurrentSpell=='Vampire\'s Bite' then
		enemies[target].HP=enemies[target].HP-player.Bite
		if player.BaseHP>10+player.Bite then
			player.BaseHP=player.BaseHP-player.Bite
		end
	end
end

function EnemyAttack()
	if #enemies>0 then
		for i=1, #enemies, 1 do
			if rendered[enemies[i].Y][enemies[i].X]==1 and math.sqrt((player.X-enemies[i].X)^2+(player.Y-enemies[i].Y)^2)<=enemies[i].Range then
				player.HP=player.HP-(enemies[i].Damage+1)
			end
		end
	end
end

function TickAilments()
	if #player.Ailments>0 then
		for i=#player.Ailments, 1, -1 do
			player.HP=player.HP-player.Ailments[i][1]
			player.Ailments[i][2]=player.Ailments[i][2]-1
			if player.Ailments[i][2]==0 then
				table.remove(player.Ailments, i)
			end
		end
	end
	
	if #enemies>0 then
		for i=1, #enemies, 1 do
			if #enemies[i].Ailments>0 then
				for i=1, #enemies, 1 do
					for u=#enemies[i].Ailments, 1, -1 do
						enemies[i].HP=enemies[i].HP-enemies[i].Ailments[u][1]
						enemies[i].Ailments[u][2]=enemies[i].Ailments[u][2]-1
						if enemies[i].Ailments[u][2]==0 then
							table.remove(enemies[i].Ailments, u)
						end
					end
				end
			end
		end
	end
end

function CheckHealth()
	if #enemies>0 then
		for i=#enemies, 1, -1 do
			if enemies[i].HP<=0 then
				player.HP=player.HP+math.floor(enemies[i].BaseHP/2)
				player.BaseHP=player.BaseHP+math.floor(enemies[i].BaseHP/2)
				table.remove(enemies, i)
			end
		end
	end
end

function Populate(enCount)
	local spots={}
	cnt=0
	for y=2, #map-1, 1 do
		for x=2, #map[1]-1, 1 do
			if map[y][x]==0 and (player.X~=x and player.Y~=y) then
				cnt=cnt+1
				spots[cnt]={x, y}
			end
		end
	end
	for i=1, enCount, 1 do
		if #spots>1 then
			local rnd=math.random(1, cnt)
			local en=math.random(1, 2)
			if en==1 then
				enemies[i]=NewEnemy(spots[rnd][1], spots[rnd][2], 10+3*floor, 2+3*floor, 1, 'Goblin15.png')
			else
				enemies[i]=NewEnemy(spots[rnd][1], spots[rnd][2], 6+2*floor, 1+2*floor, 3.5, 'Skeleton15.png')
			end
			table.remove(spots, rnd)
		else
			break
		end
	end
	local rnd=math.random(1, cnt)
	stairsX=spots[rnd][1]
	stairsY=spots[rnd][2]
	table.remove(spots, rnd)
end

function EnemyMove()
	if #enemies>0 then
		for i=1, #enemies, 1 do
			if rendered[enemies[i].Y][enemies[i].X]==1 and math.sqrt((player.X-enemies[i].X)^2+(player.Y-enemies[i].Y)^2)>enemies[i].Range then
				local xdist=math.abs(player.X-enemies[i].X)
				local ydist=math.abs(player.Y-enemies[i].Y)
				local hit=0
				if xdist~=0 and xdist>ydist then
					if player.X>enemies[i].X then
						hit=TryMove(enemies[i].X+1, enemies[i].Y, i)
					else
						hit=TryMove(enemies[i].X-1, enemies[i].Y, i)
					end
					if hit==1 then
						if player.Y>enemies[i].Y then
							hit=TryMove(enemies[i].X, enemies[i].Y+1, i)
						else
							hit=TryMove(enemies[i].X, enemies[i].Y-1, i)
						end
					end
				else
					if player.Y>enemies[i].Y then
						hit=TryMove(enemies[i].X, enemies[i].Y+1, i)
					else
						hit=TryMove(enemies[i].X, enemies[i].Y-1, i)
					end
					if hit==1 then
						if player.X>enemies[i].X then
							hit=TryMove(enemies[i].X+1, enemies[i].Y, i)
						else
							hit=TryMove(enemies[i].X-1, enemies[i].Y, i)
						end
					end
				end
			end
		end
	end
end

function TryMove(x, y, i)
	if map[y][x]~=0 or (player.X==x and player.Y==y) then
		return 1
	else
		for u=1, #enemies, 1 do
			if u~=i then
				if enemies[u].X==x and enemies[u].Y==y then
					return 1
				end
			end
		end
	end
	enemies[i].X=x
	enemies[i].Y=y
	return 0
end

function NewFloor()
	floor=floor+1
	Generate(stairsX, stairsY, 300, 7)
	Populate(5+floor)
	cursorX=player.X
	cursorY=player.Y
end

function GameOver()
	if player.HP<=0 then
		love.graphics.print('GAME OVER')
	end
end

function NewGame()
	math.randomseed(os.time())
	floor=0
	stairsX=15
	stairsY=15
	Generate(15, 15, 300, 7)
	player=newPlayer(15, 15, 20, 5.5, 'Bleed', 2)
	Populate(5)
	
	cursorX=player.X
	cursorY=player.Y
end