local rakConst = require("RHooks.const")
local raknet = require("RHooks.core")
local sampfuncs = require("RHooks.classes.sampfuncs")
local Utils = require("RHooks.classes.utils")

local utils = Utils:new()


local IRHooks = {}
function IRHooks:new()        
    local public 
    local private
    private = {}                
        function private:createHandler(typeHandler, callback)
            local handlers = raknet.handlers[typeHandler]                         
            table.insert(handlers, {callback = callback, processing = true})            
            local data = {
                index = #handlers,
                pHandler = callback
            }                   
            return setmetatable(data, {
                __index = {
                    start = function(self)
                        handlers[self.index].processing = true
                    end,
                    stop = function(self)
                        handlers[self.index].processing = false
                    end,
                    destroy = function(self)                                                                                                                    
                        for iHandler, data in ipairs(handlers) do                                                                                  
                            if (self.pHandler == data.pHandler) then                                                                
                                table.remove(handlers, iHandler)
                            end 
                        end 
                    end,
                    getIndex = function(self)
                        return self.index
                    end
                }                                
            })         
        end   

    public = {}
        -- �������� �� ������������� ����������
        function public:isInitialized()
            return (raknet.pRakClient and raknet.pRakPeer)
        end

        -- ��������� ���������� ����������, ����������� ��������� ������� SampFuncs
        function public:addSupportForSampfuncsFunctions()            
            -- raknetSendRpc = self.sendRpc
            -- function raknetSendRpc(id, bs)
            --     return self:sendRpc(id, bs)
            -- end  
            
            -- function raknetSendBitStream(bs)
            --     return self:sendPacket(bs)
            -- end

            -- local rakEvents = {["onSendPacket"], ["onReceivePacket"], ["onSendRPC"], ["onReceiveRPC"]}
            -- local originalAddEventHandler = addEventHandler
            -- function addEventHandler(eventName, callback)   
            --     print(rakEvents[eventName])             
            --     if rakEvents[eventName] then
            --         print("new func")
            --         self[eventName](self, callback)
            --     else
            --         originalAddEventHandler(eventName, callback)
            --     end
            -- end
        end

        -- �������� ������ �� ������, ��������� � ���� ��������� �� BitStream
        function public:sendPacket(bs)           
            if not self:isInitialized() then return false end                                                                               
            return raknet.originalOutgoingPacket(raknet.pRakClient, bs, rakConst.HIGH_PRIORITY, rakConst.RELIABLE_ORDERED, 0)
        end

        -- function public:emulPacket(id, bs)           
        --     if not self:isInitialized() then return false end                                                                               
        --     return raknet.originalIncomingPacket(raknet.pRakClient, bs, rakConst.HIGH_PRIORITY, rakConst.RELIABLE_ORDERED, 0)
        -- end

        -- �������� RPC �� ������, ��������� � ���� ID RPC � ��������� �� BitStream
        function public:sendRpc(id, bs)           
            if not self:isInitialized() then return false end                                                                          
            return raknet.RPC(raknet.pRakClient, id, bs, rakConst.HIGH_PRIORITY, rakConst.RELIABLE_ORDERED, 0, false)
        end

        --[[
        -- ��������� ����������� �� ��������� ������, ��������� � ���� ��������� �� �������-����������,
        -- ����������� � ����: bitStream, priority, reliability, orderingChannel
        ]]
        function public:onSendPacket(callback)
            return private:createHandler("outgoingPacket", callback)                           
        end

        --[[
            ��������� ����������� �� �������� ������, ��������� � ���� ��������� �� �������-����������,
            ����������� � ����: bitStream, priority, reliability, orderingChannel
        ]]
        function public:onReceivePacket(callback)   
            return private:createHandler("incomingPacket", callback)                                           
        end

        --[[
            ��������� ����������� �� ��������� RPC, ��������� � ���� ��������� �� �������-����������,
            ����������� � ����: id, bitStream, priority, reliability, orderingChannel, shiftTimestamp
        ]]
        function public:onSendRpc(callback)             
            return private:createHandler("outgoingRpc", callback)     
        end 

        --[[
            ��������� ����������� �� �������� RPC, ��������� � ���� ��������� �� �������-����������,
            ����������� � ����: id, bitStream, priority, reliability, orderingChannel, shiftTimestamp
        ]]
        function public:onReceiveRpc(callback)   
            return private:createHandler("incomingRpc", callback)                                     
        end
        
        -- �������� ����������� �� �������, ��������� � ����: ��� ����������� � ��� ������
        function public:destroyHandlerByIndex(handlerType, iHandler)         
            local handler = raknet.handlers[handlerType]               
            if handler[iHandler] then         
                if handler then                  
                    table.remove(handler, iHandler)
                else
                    utils:warningMessage("�������� ����������� ������� �������.")
                end
            else
                utils:warningMessage(("����������� � ��������: %s - �� ����������."):format(iHandler))
            end
        end

        -- ���������� ������� � ����������� � ���� ������������
        function public:getAllHandlers() 
            local handlers = raknet.handlers                     
            return setmetatable({}, {
                __index = handlers,                
                __newindex = function() utils:warningMessage("������� ���������� ��� ���������.") end,
                __pairs = function() return pairs(handlers) end,
                __len = function() return #handlers end
            })
        end

        -- ��������� ������� ���������, ��������� ��������, RPC � �������
        function public:setHookCreatedPacket(actived)

        end

    setmetatable(public, self)
    self.__index = self
    return public
end


return IRHooks