-----------------------------------------------------------------------
-- Luthon-object: 类似Python的面向对象简易实现。
-----------------------------------------------------------------------
Object = {
    -- 女娲，所有的类都基于她派生。可以用 Object:Fork() 派生一个类。
    Fork = function (self, class)
        -- 派生类。
        class = class or {}

        -- 派生类继承自Object。
        self.__index = self
        setmetatable(class, self)

        -- 通过派生类创建实例对象。派生类的时候可以通过重写此方法，修改实例对象的创建行为。
        class.__new__ = class.__new__ or self.__new__

        -- 通过派生类初始化实例对象。派生类的时候可以通过重写此方法，为实例对象绑定属性值。
        class.__init__ = class.__init__ or function () end

        -- 通过派生类获取其父类。
        class.Super = function (klass)
            return getmetatable(klass)
        end

        -- 使派生类具有直接调用创建实例对象的能力。
        self.__call = class.__new__
        return class
    end,

    -- 创建类实例对象。
    __new__ = function (klass, ...)
        local instance = {
            -- 通过实例对象获取父类。
            Super = function (ins)
                return getmetatable(getmetatable(ins))
            end
        }
        klass.__index = klass
        setmetatable(instance, klass)
        instance:__init__(...)
        return instance
    end,

    -- Object 的父类是他自己。
    Super = function (self)
        return self
    end,

    -- 获取继承链。
    GetInhertList= function (self)
        local inhertList = {}
        local currClass = self
        while currClass ~= nil do
            table.insert(inhertList, currClass)
            currClass = getmetatable(currClass)
        end
        return inhertList
    end,
}


-----------------------------------------------------------------------
-- 使用范例。Animal 通过 Object 派生，它及它的子类都将拥有 Object 的能力。
-----------------------------------------------------------------------
Animal = Object:Fork{
    __init__ = function (self, age)
        self.age = age
    end,
    Say = function ()
        return 'noise...'
    end
}

-- Dog 继承自 Animal。
Dog = Animal:Fork{
    __init__ = function (self, name, age)
        self.name = name

        -- 注意，此处不能使用 self:Super():__init__(age) 的调用形式，
        -- 实例对象调父类的方法应对实例对象本身操作，而不应是父类。
        self:Super().__init__(self, age)
    end,
    Say = function ()
        return "wang wang..."
    end,
}

local wangcai = Dog('wangcai', 3)
print(string.format("名字：%s,\t年龄：%d,\t对你：%s", wangcai.name, wangcai.age, wangcai:Say()))
---------------------- 输出 ----------------------
-- 名字：wangcai,	年龄：3,	对你：wang wang...
--------------------------------------------------

-- **** 获取继承链
local wangcaiInhertList = wangcai:GetInhertList()
local map = {
    [Object]  = 'Object',
    [Animal]  = 'Animal',
    [Dog]     = 'Dog',
    [wangcai] = 'wangcai'
}
print("wangcai's inhert list is:")
for i, v in pairs(wangcaiInhertList) do
    print('\t', i, map[v])
end
---------------------- 输出 ----------------------
-- wangcai's inhert list is:
-- 		1	wangcai
-- 		2	Dog
-- 		3	Animal
-- 		4	Object
--------------------------------------------------

-- **** 修改实例对象创建行为（以创建一个单例的类为范例）。
Singleton = Object:Fork{
    __new__ = function (cls, ...)
        if cls.__instance__ == nil then
            -- 注意这里的写法，不能用 cls:Super():__new__(cls)，
            -- 创建实例对象应基于当前类，而不是父类，与前面类似。
            cls.__instance__ = cls:Super().__new__(cls, ...)
        end
        return cls.__instance__
    end,
    __init__ = function (self, name)
        print("call Singleton's __init__ method! name = ".. name)
        self.name = name
    end,
}
local instance1 = Singleton('instance1')
local instance2 = Singleton('instance2')
local instance3 = Singleton('instance3')
print(string.format("instance1, id=%s, name=%s", tostring(instance1), instance1.name))
print(string.format("instance2, id=%s, name=%s", tostring(instance2), instance2.name))
print(string.format("instance3, id=%s, name=%s", tostring(instance3), instance3.name))
------------------------- 输出 -------------------------
-- call Singleton's __init__ method! name = instance1
-- instance1, id=table: 009F07B0, name=instance1
-- instance2, id=table: 009F07B0, name=instance1
-- instance3, id=table: 009F07B0, name=instance1
--------------------------------------------------------
