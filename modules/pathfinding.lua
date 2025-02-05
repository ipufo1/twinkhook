-- ipufo is the best
local round = math.round;
local len = rawlen;

local Pathfinding = {};

Pathfinding.Cardinals = {
    Vector3.new(0, 1, 0);
    Vector3.new(0, -1, 0);

    Vector3.new(1, 0, 0);
    Vector3.new(-1, 0, 0);

    Vector3.new(0, 0, 1);
    Vector3.new(0, 0, -1);

    Vector3.new(1, 0, 1);
    Vector3.new(1, 0, -1);
    Vector3.new(-1, 0, 1);
    Vector3.new(-1, 0, -1);

    Vector3.new(1, 1, 0);
    Vector3.new(1, -1, 0);
    Vector3.new(-1, 1, 0);
    Vector3.new(-1, -1, 0);

    Vector3.new(0, 1, 1);
    Vector3.new(0, 1, -1);
    Vector3.new(0, -1, 1);
    Vector3.new(0, -1, -1);
}


Pathfinding.Timeout = 123123;
Pathfinding.NodeStep = 5;
Pathfinding.Ignore = {};

local Balls = Instance.new('Folder',workspace);
table.insert(Pathfinding.Ignore, Balls);

local function GridSnap( Position, NodeStep )
    local X = round( Position.X / NodeStep ) * NodeStep;
    local Y = round( Position.Y / NodeStep ) * NodeStep;
    local Z = round( Position.Z / NodeStep ) * NodeStep;

    return Vector3.new( X, Y, Z );
end;

local function NewNode( Position, Parent, NodeStep )
    local Node = {}

    Node.Position = GridSnap( Position, NodeStep );
    Node.Parent = Parent or nil;

    Node.Cost = 0;
    Node.G = 0;
    Node.H = 0;

    Node.Scanned = false;

    return Node;
end;

local function IsWalkable( Start, End )
    local Parameters = RaycastParams.new();
    Parameters.FilterDescendantsInstances = Pathfinding.Ignore;

    return workspace:Raycast( Start, ( End - Start ), Parameters ) == nil;
end;

local function IsClosedNode( Closed, Position )
    for Index, Node in next, ( Closed ) do
        if (Node.Position == Position) then
            return true;
        end;
    end;

    return false;
end;

local function DoesExist( Open, Position )
    for Index, Node in next, ( Open ) do
        if (Node.Position == Position) then
            return true;
        end;
    end;

    return false;
end;

local function Reverse( Table )
    local Reversed = {};
    local Length = len( Table );

    for Index = 1, Length do
        Reversed[ Index ] = Table[Length - Index + 1]
    end;

    return Reversed;
end;

local function Heuristic( a, b )
    return ( a - b ).Magnitude;
end;

local RenderStepped = game:GetService('RunService').PreRender;

function Pathfinding.findPath( Start, End, NodeStep, ThreadAmount )
    local ClosedList = {} -- nodes we cant goto
    local OpenList = {} -- nodes we can search

    local StartNode = NewNode( Start, nil, NodeStep );
    local EndNode = NewNode( End, nil, NodeStep );

    StartNode.Cost = math.huge;

    local CurrentNode = StartNode;
    OpenList[ 1 ] = StartNode;

    local StartTime = tick();
    while ( tick() - StartTime ) < Pathfinding.Timeout and ( len(OpenList) > 0 ) do
        CurrentNode = OpenList[ 1 ]; -- live off hopes and prayers
        for Index, OpenNode in next, ( OpenList ) do
            if ( OpenNode.Cost < CurrentNode.Cost and OpenNode.Scanned == false ) then
                CurrentNode = OpenNode;
            end;
        end;

        local NodePosition = CurrentNode.Position;

        if Heuristic(NodePosition, EndNode.Position) < (Pathfinding.NodeStep + 1) then
            local Path = {};

            local Node = CurrentNode;
            while Node.Parent ~= nil do
                Path[ len(Path) + 1 ] = Node.Position;
                Node = Node.Parent;
            end;

            return Reverse(Path);
        end

        local Children = {};
        do -- create children
            for Index, Cardinal in next, ( Pathfinding.Cardinals ) do
                local ChildPosition = NodePosition + ( Cardinal * NodeStep );
                local ChildNode = NewNode( ChildPosition, CurrentNode, NodeStep );

                if IsClosedNode( ClosedList, ChildPosition ) then continue end;
                if DoesExist( OpenList, ChildPosition ) then continue end;

                if IsWalkable( NodePosition, ChildPosition ) then
                    Children[ len(Children) + 1 ] = ChildNode;
                end;
            end;
        end;

        -- lets calculate the costs

        --[[

            g: the distance between the start node and current node
            h: the distance betwwn the end node and current node

            f = g + h

        ]]

        for Index, Child in next, ( Children ) do
            local GCost = CurrentNode.G;
            local HCost = Heuristic( Child.Position, EndNode.Position );

            Child.Cost = GCost + HCost;
            Child.G = GCost + 1;
            Child.H = HCost;

            OpenList[ len( OpenList ) + 1 ] = Child;
        end;

        CurrentNode.Scanned = true;

        do -- visualize the node scanned
            local Stupid = Instance.new('Part', Balls);

            Stupid.Anchored = true;
            Stupid.CanCollide = false;
            Stupid.Size = Vector3.one / 2;
            Stupid.Material = Enum.Material.ForceField;
            Stupid.Position = NodePosition;
            Stupid.Color = Color3.new(1, 1, 0);
            Stupid.Shape = Enum.PartType.Ball;
        end;

        RenderStepped:Wait();
    end;
end;

return Pathfinding;
