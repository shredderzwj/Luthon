-----------------------------------------------------------------------
-- Luthon-object: 类似Python的面向对象简易实现。
-----------------------------------------------------------------------

local instanceNotSupportMethods = {
    Fork = true,
    __new__ = true,
    __mro__ = true,
    __directsubclasses__ = true,
    __subclasses__ = true,
    IsSubClassOf = true,
}

-- 递归获取一个类所有的直接子类和间接子类。
local function GetAllSubClasses(class, result)
    for _, son in pairs(class.__directsubclasses__) do
        table.insert(result, son)
        GetAllSubClasses(son, result)
    end
    return result
end

-- 注意，类的定义一般都是全局变量，这里记录类的子类，是在派生类的时候将子类写入父类的__directsubclasses__属性表中，
-- 这就导致了，子类无论是全局定义还是临时定义，因为在父类的__directsubclasses__属性表有记录，它的引用计数一直不会被清零，
-- 因此它将不会被垃圾回收机制释放掉，大量动态创建有内存泄露的风险，所以，如果有动态创建临时类的用法，建议将记录子类的功能删除掉。
local Object = {
    -- 女娲，所有的类都基于她派生。可以用 Object:Fork() 派生一个类。
    Fork = function (self, class)
        -- 派生类。
        class = class or {}

        -- 通过派生类创建实例对象。派生类的时候可以通过重写此方法，修改实例对象的创建行为。
        class.__new__ = class.__new__ or self.__new__

        -- 通过派生类初始化实例对象。派生类的时候可以通过重写此方法，为实例对象绑定属性值。
        -- 在创建实例对象的时候会调用此方法。
        class.__init__ = class.__init__ or function () end

        -- 记录类的直接子类，(使用弱引用表，方便垃圾回收)
        class.__directsubclasses__ = setmetatable({}, {__mode='v'})
        table.insert(self.__directsubclasses__, class)

        -- 使派生类具有直接调用创建实例对象的能力。
        self.__call = class.__new__

        -- 派生类继承自self（谁:Fork，这个self就是谁），即父类。
        self.__index = self

        return setmetatable(class, self)
    end,

    -- 创建类实例对象。
    __new__ = function (class, ...)
        class.__newindex = function (t, key, value)
            -- 实例对象不允许绑定 __new__ 属性，应为此属性特殊的用来判断是否是一个实例对象。
            if key ~= "__new__" then
                rawset(t, key, value)
            end
        end

        class.__index = function (_, key)
            -- 屏蔽实例对象不支持的类方法&属性
            if not instanceNotSupportMethods[key] then
                return class[key]
            end
        end

        -- 在定义类的时候如果重写的 __call__ 方法，使实例对象拥有可调用能力。
        class.__call = class.__call__

        -- 创建实例对象，并使其用于类的属性和行为（除了上面屏蔽的东西）。
        local instance = setmetatable({}, class)
        class.__init__(instance, ...)
        return instance
    end,

    -- 获取类型（实例对象的类型是其类，类的类型是Object，Object的类型还是它自己）
    __type__ = function (self)
        if self:IsIntance() then
            return getmetatable(self)
        end
        local inhertList = self:__mro__()
        return inhertList[#inhertList]
    end,

    -- 获取继承链。
    __mro__ = function (self)
        local inhertList = {}
        local currClass = self
        while currClass ~= nil do
            table.insert(inhertList, currClass)
            currClass = getmetatable(currClass)
        end
        return inhertList
    end,

    __directsubclasses__ = setmetatable({}, {__mode='v'}),

    -- 获取类的所有子类
    __subclasses__ = function (self)
        -- 非递归实现
        -- local result = {}
        -- local stack = {}
        -- local classes = self.__directsubclasses__
        -- while #stack ~= 0 or classes ~= nil do
        --     for _, son in pairs(classes) do
        --         table.insert(result, son)
        --         table.insert(stack, son.__directsubclasses__)   -- 下一级进栈。
        --     end
        --     classes = table.remove(stack)  -- 出栈。当栈为空，则说明遍历完毕，循环结束。
        -- end

        return GetAllSubClasses(self, {})
    end,

    -- 获取父类（Object 的父类是他自己）。
    Super = function (self)
        if self:IsIntance() then
            return getmetatable(getmetatable(self))
        end
        return getmetatable(self) or self
    end,

    -- 判断是否为实例对象
    IsIntance = function (self)
        return rawget(self, "__new__") == nil
    end,

    -- 判断是否是某类的实例对象
    IsInstanceOf = function (self, instance)
        if not self:IsIntance() then
            return false
        end
        return self:__type__():IsSubClassOf(instance)
    end,

    -- 判断类是否为某类的子类
    IsSubClassOf = function (self, class)
        local inhertList = self:__mro__()
        for i = 1, #inhertList do
            if inhertList[i] == class then
                return true
            end
        end
        return false
    end,
}

return Object