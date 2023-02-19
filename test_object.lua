local Object = require("object")

-- *****************************************************************************************
-- 使用范例。Animal 通过 Object 派生，它及它的子类都将拥有 Object 的能力。
-- *****************************************************************************************
local Animal = Object:Fork{
    __classname__ = 'Animal',
    __init__ = function (self, age)
        self.age = age
    end,
    Say = function ()
        return 'noise...'
    end
}

-- Dog 继承自 Animal。
local Dog = Animal:Fork{
    __classname__ = 'Dog',
    __init__ = function (self, name, age)
        self.name = name

        -- 注意，此处不能使用 self:Super():__init__(age) 的调用形式，
        -- 实例对象调父类的方法应对实例对象本身操作，而不应是父类。
        self:Super().__init__(self, age)
    end,
    __call__ = function (self)
        return self:Say()
    end,
    Say = function ()
        return "wang wang..."
    end,
}

local wangcai = Dog('wangcai', 3)
print(string.format("名字：%s,\t年龄：%d,\t对你：%s", wangcai.name, wangcai.age, wangcai()))
---------------------- 输出 ----------------------
-- 名字：wangcai,	年龄：3,	对你：wang wang...
--------------------------------------------------

-- **** 获取继承链
local map = {
    [Object]  = 'Object',
    [Animal]  = 'Animal',
    [Dog]     = 'Dog',
    [wangcai] = 'wangcai'
}
print("Dog's inhert list is:")
for i, v in pairs(Dog:__mro__()) do
    print('\t', i, map[v])
end
print()
---------------------- 输出 ----------------------
-- Dog's inhert list is:
-- 		1	Dog
-- 		2	Animal
-- 		3	Object
--------------------------------------------------

-- **** 修改实例对象创建行为（以创建一个单例的类为范例）。
local Singleton = Object:Fork{
    __classname__ = 'Singleton',
    __new__ = function (cls, ...)
        if cls.instance == nil then
            -- 注意这里的写法，不能用 cls:Super():__new__(cls)，
            -- 创建实例对象应基于当前类，而不是父类，与前面类似。
            cls.instance = cls:Super().__new__(cls, ...)
        end
        return cls.instance
    end,
    __init__ = function (self, name)
        print("调用了初始化方法：name = ".. name)
        self.name = name
    end,
}
print('单例创建类的测试：')
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



-- *****************************************************************************************
-- 利用类的继承链，实现自关联表继承关系的判断。复杂度：时间O(n)，空间O(n)
-- *****************************************************************************************
local InhertTreeCls = Object:Fork{
    __classname__ = 'InhertTreeCls',
    __init__ = function (self)
        self.root = '中国'
        self.relationship = {
            ['河南'] = '中国',
            ['江苏'] = '中国',
            ['山东'] = '中国',
            ['郑州'] = '河南',
            ['开封'] = '河南',
            ['中牟'] = '郑州',
            ['巩义'] = '郑州',
            ['苏州'] = '江苏',
            ['南京'] = '江苏',
            ['江宁'] = '南京',
            ['潍坊'] = '山东',
            ['洛阳'] = '河南',
            ['兰考'] = '开封',
        }
        self.relationshipMapParrentAsKey = self:GetrelationshipMapParrentAsKey()
    end,
    GetrelationshipMapParrentAsKey = function (self)
        local relationshipMapParrentAsKey = {}
        for son, parrent in pairs(self.relationship) do
            relationshipMapParrentAsKey[parrent] = relationshipMapParrentAsKey[parrent] or {}
            table.insert(relationshipMapParrentAsKey[parrent], son)
        end
        return relationshipMapParrentAsKey
    end,
    GetInhertRelationshipMap = function (self)
        -- 转换为以父类型为key的映射表。
        local relationshipMapParrentAsKey = self.relationshipMapParrentAsKey

        -- 根节点为:Object
        local valueClassMap = {[self.root] = Object}

        -- 通过递归遍历继承树，创建派生类，并将创建的派生类存入 值-类 的映射表。
        local function Create(parrent)
            for _, son in pairs(relationshipMapParrentAsKey[parrent] or {}) do
                valueClassMap[son] = valueClassMap[parrent]:Fork{__classname__ = son}
                Create(son)
            end
        end
        Create(self.root)

        return valueClassMap
    end,
    IsInInhertLink = function (self, value1, value2)
        --[[ 判断两个值对否在同一条继承链上 ]]--
        if value1 == value2 then
            return true
        end

        local valueClassMap = self:GetInhertRelationshipMap()

        -- 根据传进来的值，获取其对应的类。
        local cls1 = valueClassMap[value1]
        local cls2 = valueClassMap[value2]

        if cls1 == nil or cls2 == nil then
            return false
        end

        -- 判断是否在继承链上。
        if cls1:IsSubClassOf(cls2) or cls2:IsSubClassOf(cls1) then
            return true
        end
        return false
    end,
    GeneraTreeTab = function (_, number)
        local str = ""
        for _ = 2, number do
            str = str .. "|   "
        end
        if number >= 1 then
            str = str .. "|---"
        end
        return str
    end,
    PrintInhertTree = function (self)
        local relationshipMapParrentAsKey = self:GetrelationshipMapParrentAsKey()

        -- 通过递归遍历继承树，打印信息。
        print(string.format('%s%s', self:GeneraTreeTab(0), self.root))
        local function PrintSonNodes(parrent, deep)
            local sonList = relationshipMapParrentAsKey[parrent] or {}
            table.sort(sonList, function (a, b)
                return a < b
            end)
            for _, son in pairs(sonList) do
                print(string.format('%s%s', self:GeneraTreeTab(deep), son))
                PrintSonNodes(son, deep + 1)
            end
        end
        PrintSonNodes(self.root, 1)
    end
}

local InhertTree = InhertTreeCls()
print('\n是否在继承链上判断：')
print('\t', '中牟', '南京', InhertTree:IsInInhertLink('中牟', '南京'))      -- false
print('\t', '山东', '苏州', InhertTree:IsInInhertLink('山东', '苏州'))      -- false
print('\t', '开封', '苏州', InhertTree:IsInInhertLink('开封', '苏州'))      -- false
print('\t', '乌鲁木齐', '苏州', InhertTree:IsInInhertLink('乌鲁木齐', '苏州'))  -- false
print('\t', '郑州', '河南', InhertTree:IsInInhertLink('郑州', '河南'))      -- true
print('\t', '中国', '江宁', InhertTree:IsInInhertLink('中国', '江宁'))      -- true

print('\n继承树：')
InhertTree:PrintInhertTree()


print('\n垃圾回收前：')
for index, value in pairs(Object:__subclasses__()) do
    print('\t', index, value.__classname__)
end

collectgarbage()

print('\n垃圾回收后：')
-- 那些在函数里面临时定义的类已经被清除掉。
for index, value in pairs(Object:__subclasses__()) do
    print('\t', index, value.__classname__)
end
