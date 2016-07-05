
local MyLevels=import("..data.MyLevels")
local MyCoin   = import("..views.MyCoin")

local Board = class("Board", function()
    return display.newNode()
end)

local NODE_PADDING   = 100
local NODE_ZORDER    = 0

local COIN_ZORDER    = 1000

function Board:ctor(levelData)
    cc.GameObject.extend(self):addComponent("components.behavior.EventProtocol"):exportMethods()
    self.batch = display.newNode()
    self.batch:setPosition(display.cx, display.cy)
    self:addChild(self.batch)

    self.grid = clone(levelData.grid)
    self.rows = levelData.rows
    self.cols = levelData.cols
    self.coins = {}
    self.flipAnimationCount = 0
    self.deleteQueue={}
    self.tmpWidthQueue={}
    self.tmpHeightQueue={}

    
    -- create board, place all coins
    
    if self.cols>6 then
        SCALE=CONFIG_SCREEN_WIDTH/(self.cols*NODE_PADDING)
    else
        SCALE=1
    end

    local ADJUST_NODE_PADDING=NODE_PADDING*SCALE

    local offsetX = -math.floor(ADJUST_NODE_PADDING * self.cols / 2) - ADJUST_NODE_PADDING / 2
    local offsetY = -math.floor(ADJUST_NODE_PADDING * self.rows / 2) - ADJUST_NODE_PADDING / 2
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    for row = 1, self.rows do
        local y = row * ADJUST_NODE_PADDING + offsetY
        for col = 1, self.cols do
            local x = col * ADJUST_NODE_PADDING + offsetX
            local nodeSprite = display.newSprite("#BoardNode.png", x, y)
                nodeSprite:setScale(SCALE);
            self.batch:addChild(nodeSprite, NODE_ZORDER)
            local node = self.grid[row][col]
            if node ~= MyLevels.NODE_IS_EMPTY then
                local coin = MyCoin.new(node)
                coin:setScale(SCALE*2);
                coin:setPosition(x, y)
                coin:setTag(row*10+col)
                coin.row = row
                coin.col = col
                self.grid[row][col] = coin
                self.coins[#self.coins + 1] = coin
                self.batch:addChild(coin, COIN_ZORDER)
            end
        end
    end

    self:setNodeEventEnabled(true)
    self:setTouchEnabled(true)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        return self:onTouch(event.name, event.x, event.y)
    end)

end

function Board:findLeft( coin)
    local num=0
    local row=coin.row
    local col=coin.col
    if row>1 then
        local node=self.grid[row - 1][col]
        if self:isInDeleteQueue(node) then
        else
            if node.type==coin.type then
                self.tmpWidthQueue[#self.tmpWidthQueue+1]=node
                return self:findLeft(node)+1
           end
       end
   end
   return 0
end

function Board:findRight( coin)
    local row=coin.row
    local col=coin.col
    if row<self.rows then
        local node=self.grid[row +1][col]
        if self:isInDeleteQueue(node) then
        else
            if node.type==coin.type then
                self.tmpWidthQueue[#self.tmpWidthQueue+1]=node
               return self:findLeft(node)+1
           end
       end
   end
   return 0
end

function Board:findTop(coin)
    local row=coin.row
    local col=coin.col
    if col>1 then
        local node=self.grid[row][col-1]
         if self:isInDeleteQueue(node) then
        else
            if node.type==coin.type then
               self.tmpHeightQueue[#self.tmpHeightQueue+1]=node
               return self:findTop(node)+1
           end
        end
    end
    return 0
end

function Board:findBottom( coin)
    local row=coin.row
    local col=coin.col
    if col<self.cols then
        local node=self.grid[row][col+1]
        if self:isInDeleteQueue(node) then
        else
            if node.type==coin.type then
                self.tmpHeightQueue[#self.tmpHeightQueue+1]=node
                return self:findBottom(node)+1
            end
        end
    end
    return 0
end
function Board:addWidthDeleteQueue()
    for k,v in pairs(self.tmpWidthQueue) do
        if self:isInDeleteQueue(v) then
        else
           self.deleteQueue[#self.deleteQueue+1]=v
           v=nil
       end

   end
end
function Board:addHeightDeleteQueue()
    for k,v in pairs(self.tmpHeightQueue) do
       if self:isInDeleteQueue(v) then
       else
           self.deleteQueue[#self.deleteQueue+1]=v
           v=nil
       end
   end
end

function Board:cleanTmpWidthQueue()
   for k,v in pairs(self.tmpWidthQueue) do
        end
end

function Board:cleanTmpHeightQueue()
    for k,v in pairs(self.tmpHeightQueue) do
        end
end
function Board:findStar(coin)
    local widthNum=self:findLeft(coin)+self:findRight(coin)
    local heightNum=self:findTop(coin)+self:findBottom(coin)
    print(widthNum,heightNum)
    if widthNum <2 and heightNum<2 then
        
    else
        if widthNum<2 then
            self:addHeightDeleteQueue()
        end
        if heightNum<2 then
        self:addWidthDeleteQueue()
        end
        self.deleteQueue[#self.deleteQueue+1]=coin
    end
    self:cleanTmpHeightQueue()
        self:cleanTmpWidthQueue()
end

function Board:searchStars()
    for row=1, self.rows do
        for col=1,self.cols do
            local node=self.grid[row][col]
            if self:isInDeleteQueue(node) then
            else
                self:findStar(node)
            end

        end              
    end
    print("search end")
end


function Board:printDeleteQueue()
    for k,v in pairs(self.deleteQueue) do
        print(v.row,v.col,k)
        v:setScale(0.5)
    end
end
function Board:isInDeleteQueue(coin)
    for k,v in pairs(self.deleteQueue) do
        if v:getTag()==coin:getTag() then 
            print(coin:getTag(),v:getTag())
            return true
        end
    end
    return false
end

function Board:checkLevelCompleted()
    local count = 0
    for _, coin in ipairs(self.coins) do
        if coin.isWhite then count = count + 1 end
    end
    if count == #self.coins then
        -- completed
        self:setTouchEnabled(false)
        self:dispatchEvent({name = "LEVEL_COMPLETED"})
    end
end

function Board:getCoin(row, col)
    if self.grid[row] then
        return self.grid[row][col]
    end
end

function Board:flipCoin(coin, includeNeighbour)
    if not coin or coin == MyLevels.NODE_IS_EMPTY then return end

    self.flipAnimationCount = self.flipAnimationCount + 1
    coin:flip(function()
        self.flipAnimationCount = self.flipAnimationCount - 1
        self.batch:reorderChild(coin, COIN_ZORDER)
        if self.flipAnimationCount == 0 then
            self:checkLevelCompleted()
        end
    end)
    if includeNeighbour then
        audio.playSound(GAME_SFX.flipCoin)
        self.batch:reorderChild(coin, COIN_ZORDER + 1)
        self:performWithDelay(function()
            self:flipCoin(self:getCoin(coin.row - 1, coin.col))
            self:flipCoin(self:getCoin(coin.row + 1, coin.col))
            self:flipCoin(self:getCoin(coin.row, coin.col - 1))
            self:flipCoin(self:getCoin(coin.row, coin.col + 1))
        end, 0.25)
    end
end

function Board:onTouch(event, x, y)
    if event ~= "began" or self.flipAnimationCount > 0 then return end

    local padding = NODE_PADDING / 2
    for _, coin in ipairs(self.coins) do
        local cx, cy = coin:getPosition()
        cx = cx + display.cx
        cy = cy + display.cy
        if x >= cx - padding
            and x <= cx + padding
            and y >= cy - padding
            and y <= cy + padding then
            self:searchStars()
            self:printDeleteQueue()
            --self:flipCoin(coin, true)
            break
        end
    end
end

function Board:onEnter()
    self:setTouchEnabled(true)
end

function Board:onExit()
    self:removeAllEventListeners()
end

return Board
