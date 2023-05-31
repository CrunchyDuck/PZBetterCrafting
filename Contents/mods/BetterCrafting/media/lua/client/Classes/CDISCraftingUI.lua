-- #region TODO
-- TODO: Figure out customRecipeName
-- TODO: Queuing intermediate recipes.
-- TODO: Show items that need to be unfrozen/cooked below the available items.
-- TODO: "Minimal mode", which displays recipes in a text-only format (akin to CDDA)
-- TODO: Hiding recipes and a hidden tab.
-- TODO: Index evolved recipes.
-- TODO: Favourited recipes.
-- TODO: Get ingredients from a larger radius.
-- TODO: If the recipe list changes, try keep the thing the player had selected, selected.
-- TODO: Sub mod that fixes some broken recipes and groups up other recipes.
-- TODO: Mention no controller support/multiplayer testing on the mod page.
-- TODO: Fix side of ingredients flickering if no scroll bar.
-- TODO: Check if learning recipes adds them to the menu.
-- TODO: Check dismantle watch recipe.
-- TODO: Change search boxes to be &&
-- TODO: Crafting box keybinds are offset. Fix them sometime.
-- TODO: Test lag with Hydrocraft.
-- TODO: Test with Craft Helper
-- TODO: When displaying evolved recipe ingredients, provide a number of that ingredient rather than multiple in list.
-- TODO: Check if any mods use evolved recipes for non-cooking.
-- TODO: Stale meat caused issues with evolved recipes.
-- #endregion
require "ISUI/ISCraftingUI"
require "CDRecipe"

ISCraftingUI = ISCollapsableWindow:derive("ISCraftingUI");

-- #region Class variables
-- Singleton.
ISCraftingUI.instance = nil;
ISCraftingUI.largeFontHeight = getTextManager():getFontHeight(UIFont.Large)
ISCraftingUI.mediumFontHeight = getTextManager():getFontHeight(UIFont.Medium)
ISCraftingUI.smallFontHeight = getTextManager():getFontHeight(UIFont.Small)
ISCraftingUI.bottomInfoHeight = ISCraftingUI.smallFontHeight * 2
ISCraftingUI.qwertyConfiguration = true;
ISCraftingUI.bottomTextSpace = "     ";
ISCraftingUI.leftCategory = Keyboard.KEY_LEFT;
ISCraftingUI.rightCategory = Keyboard.KEY_RIGHT;
ISCraftingUI.upArrow = Keyboard.KEY_UP;
ISCraftingUI.downArrow = Keyboard.KEY_DOWN;

ISCraftingUI.frameCounter_i = 0;
ISCraftingUI.baseRecipes_ar = {};  -- hs[zombie.scripting.objects.Recipe].
ISCraftingUI.allRecipes_ht = {};  -- ht[zombie.scripting.objects.Recipe, recipe]. Technically just all known recipes, but this is snappier.
ISCraftingUI.evolvedRecipeInstances_ht = {} -- ht[int, ar[CDEvolvedRecipeInstance]]
-- #region rant
--- This following hash table caused, without exaggeration,
--- 3 days of on-off bug fixing and insanity spiralling to get working.
--- The problem was simple: I could not iterate over the hash table.
---
--- Because of the dogshit error checking and batshit edge cases in lua,
--- I checked just about every possible route before finding the answer.
--- I have never felt so destitute over a piece of code as I have in Lua.
--- I could find no forum posts detailing this, no documentation outlining this.
---
--- In fixing this, I tried something simple: Count the number of entries in a dictionary.
--- It kept returning 0.
--- Even when I expressly put a key in that should get counted - ht["test"] = "testval";
--- So as a last ditch, I tried first clearing the table, adding my test, and then counting.
--- ht = {}; ht["test"] = "testval";
--- And it worked. It should not have worked.
---
--- I cannot express the myriad of swirling emotions that erupted,
--- compounding on an already quite terrible day.
---
--- For a while I thought I might have, somehow, somewhere, corrupted the compiler.
--- This behaviour was so far beyond what I expected of any programming language,
--- I believed the only possibility was that it was not in the language.
---
--- The answer?
--- I had been accidentally putting null values into my hash table here.
--- When a table has "null" as a key, it REFUSES to be iterated over past null.
--- It will throw no errors, and you can still access those keys by directly checking.
--- But iteration will not work.
---
--- I loathe this language. And yet, that is exactly why I am here.
--- In no other language would I be presented with a problem so concisely complex as this.
--- Lua, and this codebase, is like being on the front lines of an apocalyptic war.
--- It will claim me. But it challenges me to impossible problems, and makes me feel alive.
---
--- Never before have I had to do a writeup about a variable.
-- #endregion
ISCraftingUI.recipeCategories_ht = {};  -- ht[string, hs[recipe]].
ISCraftingUI.currentCategory_str = "General";
ISCraftingUI.categories_hs = {};  -- hs[str]. Used to name and track the tabs that go into panel.
ISCraftingUI.selectedRecipe = nil;
-- #region availableItems_ht explanation
--- This is effectively my own version of getAvailableItemsAll
--- So why am I gathering all the items into a table, rather than using the vanilla systems?
--- I'm making a table so that I can implement my own search to tally up how much of each thing we have.
--- While slower than the built in way (maybe), this exposes more of the code to modification
--- The vanilla method is also a confusing mess that doesn't work nicely with my object oriented rewrite.
-- #endregion
ISCraftingUI.availableItems_ht = nil;  -- ht[string, ar[zombie.inventory.InventoryItem]].
ISCraftingUI.shouldUpdateFilter_b = false;
ISCraftingUI.shouldUpdateOrder_b = false;
ISCraftingUI.lastNameFilter_str = false;
ISCraftingUI.lastComponentFilter_str = false;

-- #region UI variables
ISCraftingUI.panel = nil;
ISCraftingUI.craftOneButton = nil;
ISCraftingUI.craftAllButton = nil;
ISCraftingUI.addIngredientButton = nil

ISCraftingUI.taskLabel = nil

ISCraftingUI.recipe_listbox = nil
ISCraftingUI.hasRenderedIngredients_b = false;
ISCraftingUI.ingredientPanel = nil
ISCraftingUI.ingredientListbox = nil

ISCraftingUI.noteText = nil
ISCraftingUI.keysText = nil

ISCraftingUI.nameFilterLabel = nil
ISCraftingUI.nameFilterEntry = nil
ISCraftingUI.componentFilterLabel = nil
ISCraftingUI.componentFilterEntry = nil

ISCraftingUI.filterAll = nil

-- This should really be stored on an object somewhere, why does it need to be fetched and locally stored?
ISCraftingUI.fontHeightSmall = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight();
ISCraftingUI.fontHeightMedium = getTextManager():getFontFromEnum(UIFont.Medium):getLineHeight();
ISCraftingUI.favouriteXPos = 0;
ISCraftingUI.favouriteXPad = 20;
ISCraftingUI.favouriteStar = getTexture("media/ui/FavoriteStar.png");
ISCraftingUI.favCheckedTex = getTexture("media/ui/FavoriteStarChecked.png");
ISCraftingUI.favNotCheckedTex = getTexture("media/ui/FavoriteStarUnchecked.png");
-- #endregion
-- #endregion

-- #region Constructors
function ISCraftingUI:new(x, y, width, height, character)
    local o = {};
    if x == 0 and y == 0 then
    x = (getCore():getScreenWidth() / 2) - (width / 2);
    y = (getCore():getScreenHeight() / 2) - (height / 2);
    end
    o = ISCollapsableWindow:new(x, y, width, height);
    o.minimumWidth = 800
    o.minimumHeight = 600
    setmetatable(o, self);
    if getCore():getKey("Forward") ~= 44 then -- hack, seriously, need a way to detect qwert/azerty keyboard :(
        ISCraftingUI.qwertyConfiguration = false;
    end

    o.LabelDash = "-"
    o.LabelDashWidth = getTextManager():MeasureStringX(UIFont.Small, o.LabelDash)
    o.LabelCraftOne = getText("IGUI_CraftUI_CraftOne")
    o.LabelCraftAll = getText("IGUI_CraftUI_CraftAll")
    o.LabelAddIngredient = getText("IGUI_CraftUI_ButtonAddIngredient")
    o.LabelFavorite = getText("IGUI_CraftUI_Favorite")
    o.LabelClose = getText("IGUI_CraftUI_Close")

    o.bottomInfoText1 = getText("IGUI_CraftUI_Controls1",
        getKeyName(ISCraftingUI.upArrow), getKeyName(ISCraftingUI.downArrow),
        getKeyName(ISCraftingUI.leftCategory), getKeyName(ISCraftingUI.rightCategory));

    o.bottomInfoText2 = getText("IGUI_CraftUI_Controls2",
        getKeyName(ISCraftingUI.upArrow), getKeyName(ISCraftingUI.downArrow),
        getKeyName(ISCraftingUI.leftCategory), getKeyName(ISCraftingUI.rightCategory));

    o.title = getText("IGUI_CraftUI_Title");
    self.__index = self;
    o.character = character;
    o.playerNum = character and character:getPlayerNum() or -1
    o:setResizable(true);
    o.lineH = 10;
    o.fgBar = {r=0, g=0.6, b=0, a=0.7 }
    o.craftInProgress = false;
    o.selectedIndex = {}
    o.recipeListHasFocus = true
    o.TreeExpanded = getTexture("media/ui/TreeExpanded.png")
    o.PoisonTexture = getTexture("media/ui/SkullPoison.png")
    o.knownRecipes = RecipeManager.getKnownRecipesNumber(o.character);
    o.totalRecipes = getAllRecipes():size();
    o:setWantKeyEvents(true);
    return o;
end

function ISCraftingUI:createChildren()
    ISCraftingUI.instance = self;
    ISCollapsableWindow.createChildren(self);
    local top_handle_height = self:titleBarHeight();
    local resize_handle_height = self.resizable and self:resizeWidgetHeight() or 0

    -- Calculated for my sanity.
    local main_view_y_bottom = self.height - resize_handle_height - ISCraftingUI.bottomInfoHeight;

    local h = self.height - top_handle_height - resize_handle_height - ISCraftingUI.bottomInfoHeight;
    self.panel = ISTabPanel:new(0, top_handle_height, self.width, h);
    self.panel:initialise();
    self.panel:setAnchorRight(true)
    self.panel:setAnchorBottom(true)
    self.panel.borderColor = { r = 0, g = 0, b = 0, a = 0};
    self.panel.onActivateView = ISCraftingUI.OnActivateView;
    self.panel.target = self;
    self.panel:setEqualTabWidth(false)
    self:addChild(self.panel);

    self.craftOneButton = ISButton:new(0, self.height-ISCraftingUI.bottomInfoHeight-20-15, 50,25,getText("IGUI_CraftUI_ButtonCraftOne"),self, ISCraftingUI.craft);
    self.craftOneButton:initialise()
    self:addChild(self.craftOneButton);

    self.craftAllButton = ISButton:new(0, self.height-ISCraftingUI.bottomInfoHeight-20-15, 50,25,getText("IGUI_CraftUI_ButtonCraftAll"),self, ISCraftingUI.craftAll);
    self.craftAllButton:initialise()
    self:addChild(self.craftAllButton);

    -- self.debugGiveIngredientsButton = ISButton:new(0, 0, 50, 25, "DBG: Give Ingredients", self, ISCraftingUI.debugGiveIngredients);
    -- self.debugGiveIngredientsButton:initialise();
    -- self:addChild(self.debugGiveIngredientsButton);

    self.taskLabel = ISLabel:new(4,5,19,"",1,1,1,1,UIFont.Small, true);
    self:addChild(self.taskLabel);

    self.addIngredientButton = ISButton:new(0, self.height-ISCraftingUI.bottomInfoHeight-20-15, 50,25,getText("IGUI_CraftUI_ButtonAddIngredient"),self, ISCraftingUI.onAddIngredient);
    self.addIngredientButton:initialise()
    self:addChild(self.addIngredientButton);
    self.addIngredientButton:setVisible(false);

    self.ingredientPanel = ISScrollingListBox:new(1, 30, self.width / 3, self.height - (59 + ISCraftingUI.bottomInfoHeight));
    self.ingredientPanel:initialise()
    self.ingredientPanel:instantiate()
    self.ingredientPanel.itemheight = math.max(ISCraftingUI.smallFontHeight, 22)
    self.ingredientPanel.font = UIFont.NewSmall
    self.ingredientPanel.doDrawItem = self.RenderNonEvolvedIngredient
    self.ingredientPanel.drawBorder = true
    self.ingredientPanel:setVisible(false)
    self:addChild(self.ingredientPanel)

    -- What compelled them to use rich text for static text, and manually update it in render?
    -- self.noteRichText = ISRichTextLayout:new(self.width)
    -- self.noteRichText:setMargins(0, 0, 0, 0)
    -- self.noteRichText:setText(getText("IGUI_CraftUI_Note"))
    -- self.noteRichText.textDirty = true
    local h = ISCraftingUI.fontHeightSmall + 2 * 2;
    local x = self:getWidth() / 3 + 10;
    local y = main_view_y_bottom - h;
    self.noteText = ISLabel:new(x, y, h, getText("IGUI_CraftUI_Note"), 1, 1, 1, 1, UIFont.Small, true);
    self:addChild(self.noteText);

    local y = main_view_y_bottom + 2;
    self.keysText = ISLabel:new(0, y, h, "", 1, 1, 1, 1, UIFont.Small, true);
    self:addChild(self.keysText);


    -- self.keysRichText = ISRichTextLayout:new(self.width)
    -- self.keysRichText:setMargins(5, 0, 5, 0)

    -- == Filter area == --
    --- Why on God's green earth was this originally placed in ISCraftingCategoryUI?
    --- The majority ISCraftingCategoryUI has no business existing, and would be better served here.
    --- I try to keep my feelings toned down but my disappointment with this codebase is unmatched,
    ---   and today this is the straw that is too far for me :(
    -- local ISCraftingUI.fontHeightSmall = self.fontHeightSmall;
    -- self.panel.height - self.panel.tabHeight
    local x = 4;
    local y = self.panel:getY() + self.panel.tabHeight + 4;
    local text = getText("IGUI_CraftUI_Name_Filter");
    -- No idea what this math is aiming for.
    local filter_x = x + getTextManager():MeasureStringX(UIFont.Small, "Component Filter:") + 9;
    local filter_width = ((self.width/3) - getTextManager():MeasureStringX(UIFont.Small, text)) - 98;

    local entryHgt = ISCraftingUI.fontHeightSmall + 2 * 2;
    self.nameFilterLabel = ISLabel:new(x, y, entryHgt, text, 1,1,1,1, UIFont.Small, true);
    self:addChild(self.nameFilterLabel);
    x = filter_x;

    self.nameFilterEntry = ISTextEntryBox:new("", filter_x, y, filter_width, ISCraftingUI.fontHeightSmall);
    self.nameFilterEntry:initialise();
    self.nameFilterEntry:instantiate();
    self.nameFilterEntry:setText("");
    self.nameFilterEntry:setClearButton(true);
    self:addChild(self.nameFilterEntry);
    x = x + self.nameFilterEntry.width + 5;

    self.filterAll = ISTickBox:new(x, y, 20, entryHgt, "", self, self.OnFilterAll);
    self.filterAll:initialise();
    self.filterAll:addOption(getText("IGUI_FilterAll"));
    self.filterAll:setWidthToFit();
    self.filterAll:setVisible(true);
    self:addChild(self.filterAll);

    -- Component filter.
    x = 4;
    y = y + self.nameFilterEntry:getHeight() + 5;
    local text = "Component Filter:"
    self.componentFilterLabel = ISLabel:new(x, y, entryHgt, text, 1,1,1,1, UIFont.Small, true);
    self:addChild(self.componentFilterLabel);
    x = filter_x;

    self.componentFilterEntry = ISTextEntryBox:new("", filter_x, y, filter_width, ISCraftingUI.fontHeightSmall);
    self.componentFilterEntry:initialise();
    self.componentFilterEntry:instantiate();
    self.componentFilterEntry:setText("");
    self.componentFilterEntry:setClearButton(true);
    self:addChild(self.componentFilterEntry);
    x = x + self.componentFilterEntry.width + 5;

    y = y + entryHgt + 25;

    -- == Recipe listbox == --
    self.recipe_listbox = ISScrollingListBox:new(1, y, self.width / 3, main_view_y_bottom - y);
    self.recipe_listbox:initialise();
    self.recipe_listbox:instantiate();
    self.recipe_listbox:setAnchorRight(false) -- resize in update()
    self.recipe_listbox:setAnchorBottom(true)
    self.recipe_listbox.itemheight = 2 + ISCraftingUI.fontHeightMedium + 32 + 4;
    self.recipe_listbox.selected = 0;
    -- TODO: Add recipe listbox events
    self.recipe_listbox.doDrawItem = self.RenderRecipeList;
    self.recipe_listbox:setOnMouseDownFunction(self, self.OnChooseRecipe);
    -- self.recipe_listbox.onMouseDown = ISCraftingCategoryUI.onMouseDown_Recipes;
    -- self.recipe_listbox.onMouseDoubleClick = ISCraftingCategoryUI.onMouseDoubleClick_Recipes;
    self.recipe_listbox.joypadParent = self;
    self.recipe_listbox.drawBorder = false;
    self:addChild(self.recipe_listbox);

    self.favouriteXPos = self.recipe_listbox:getWidth() - self.favouriteXPad - self.favouriteStar:getWidth();

    self:AddCategory("Favorite");
    self:AddCategory("General");
    self:Refresh();
end

function ISCraftingUI:initialise()
    ISCollapsableWindow.initialise(self);
end
-- #endregion

-- #region Events
function ISCraftingUI:update()
    self:Refresh();
    -- if self.craftInProgress then
    --     local currentAction = ISTimedActionQueue.getTimedActionQueue(self.character);
    --     if not currentAction or not currentAction.queue or not currentAction.queue[1] then
    --         self:Refresh();
    --         self.craftInProgress = false;
    --     end
    -- end
    -- if self.needRefreshIngredientPanel then
    --     self.needRefreshIngredientPanel = false
    --     self:UpdateSelectedRecipe()
    -- end
end

function ISCraftingUI:render()
    ISCollapsableWindow.render(self);
    if self.isCollapsed then return end

    local resize_handle_height = self.resizable and self:resizeWidgetHeight() or 0
    self:drawRectBorder(0, 0, self:getWidth(), self:getHeight(), self.borderColor.a, self.borderColor.r,self.borderColor.g,self.borderColor.b);
    self.javaObject:DrawTextureScaledColor(nil, 0, self:getHeight() - resize_handle_height - ISCraftingUI.bottomInfoHeight, self:getWidth(), 1, self.borderColor.r, self.borderColor.g,self.borderColor.b,self.borderColor.a);

    local textWidth = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_CraftingUI_KnownRecipes", self.knownRecipes,self.totalRecipes))
    self:drawText(getText("IGUI_CraftingUI_KnownRecipes", self.knownRecipes,self.totalRecipes), self.width - textWidth - 5, self.panel:getY() + self.panel.tabHeight + 8, 1,1,1,1, UIFont.Small);

    local text = "";
    if self.selectedRecipe and self.selectedRecipe:IsType(CDEvolvedRecipe) then
        text = self.bottomInfoText2;
    else
        text = self.bottomInfoText1;
    end

    self.keysText:setName(text);
    local x = (self.width / 2) - (self.keysText.width / 2);
    self.keysText:setX(x);

    local position = {};
    position.x = self:getWidth() / 3 + 80;
    position.y = 110;
    local recipe = self:GetListboxSelected(self.recipe_listbox);
    if recipe == nil then
        return;
    end

    recipe = recipe.item;
    self:RenderRecipeDetails(position, recipe);
    -- TODO: Implement more from render.
end

function ISCraftingUI:setVisible(visible_b)
    self.javaObject:setVisible(visible_b);
    self.javaObject:setEnabled(visible_b)
    if true then return end;  -- DEBUG

    if not visible_b then -- save the selected index
        self.selectedIndex = {};
        for i,v in ipairs(self.categories) do
            self.selectedIndex[v.category] = v.recipes.selected;
        end
    end
    if visible_b and self.recipesList then
        self:Refresh();
    end
    if visible_b then
        for i,v in ipairs(self.categories) do
            if self.selectedIndex[v.category] then
                v.recipes.selected = self.selectedIndex[v.category];
            end
        end
    end

    self.craftInProgress = false;
    local recipeListBox = self:getRecipeListBox()
    recipeListBox:ensureVisible(recipeListBox.selected);
    if visible_b then
        self.knownRecipes = RecipeManager.getKnownRecipesNumber(self.character);
        self.totalRecipes = getAllRecipes():size();
    end
end

function ISCraftingUI:close()
    ISCollapsableWindow.close(self)
    if JoypadState.players[self.playerNum+1] then
        setJoypadFocus(self.playerNum, nil)
    end
end

function ISCraftingUI:OnChooseRecipe(data)
    self.hasRenderedIngredients_b = false;
end

function ISCraftingUI:OnFilterAll(data)
    self.shouldUpdateFilter_b = true;
    self.shouldUpdateOrder_b = true;
end

function ISCraftingUI:OnActivateView()
    self.shouldUpdateFilter_b = true;
    self.shouldUpdateOrder_b = true;
end
-- #endregion

-- #region Update functions
function ISCraftingUI:Refresh()
    -- TODO: Might move this into update itself?
    self:UpdateKnownRecipes();
    self:UpdateAvailableItems();
    self:UpdateEvolvedItems();
    self:UpdateRecipeFilter();

    self:UpdateRecipesAvailable();
    self:UpdateSelectedRecipe();

    self:UpdateRecipeOrder();

    self.frameCounter_i = self.frameCounter_i + 1;
end

function ISCraftingUI:UpdateKnownRecipes()
    -- TODO: Visible recipe only supports adding recipes for now. Add hiding support.
    -- Index normal recipes
    local recipes = getAllRecipes();  -- Java array
    for i = 0, recipes:size() - 1 do
        local recipe = recipes:get(i);
        -- Add new recipes.
        if self.allRecipes_ht[recipe] == nil then
            self.shouldUpdateFilter_b = true;
            self.shouldUpdateOrder_b = true;
            r = CDRecipe:New(recipe);
            -- r:UpdateAvailability(false);
            self:AddCDRecipe(r);
        end
    end

    -- Index evolved recipes
    local recipes = RecipeManager.getAllEvolvedRecipes();  -- java_ar[zombie.scripting.objects.EvolvedRecipe]
    for i = 0, recipes:size() - 1 do
        local base_recipe = recipes:get(i);
        if self.allRecipes_ht[base_recipe] == nil then
            local recipe = CDEvolvedRecipe:New(base_recipe);
            if recipe ~= nil then
                self:AddCDRecipe(recipe);
            end
        end
    end
end

function ISCraftingUI:UpdateRecipeFilter()
    -- Doesn't seem to be an event for key down input.
    local nf = self.nameFilterEntry:getInternalText():trim():lower();
    local cf = self.componentFilterEntry:getInternalText():trim():lower();
    if not self.shouldUpdateFilter_b and
    (nf == self.lastNameFilter_str and cf == self.lastComponentFilter_str) then
        return;
    end
    local all_b = self.filterAll:isSelected(1)
    self.shouldUpdateFilter_b = false;
    self.shouldUpdateOrder_b = true;

    self.currentCategory_str = self.panel.activeView.name;
    local selected_item = self:GetListboxSelected(self.recipe_listbox);
    self.recipe_listbox:clear();
    self.recipe_listbox.selected = -1;
    -- self.recipe_listbox:setScrollHeight(0);
    -- self.recipe_listbox.selected = s;

    local recipes_list = nil;
    if all_b then
        recipes_list = {};
        for _, recipe in pairs(self.allRecipes_ht) do
            recipes_list[recipe] = true;
        end
    else
        recipes_list = self.recipeCategories_ht[self.currentCategory_str];
    end

    --- I don't like doing it this way, but evo recipes break all the rules.
    --- I would need to rewrite how I'm storing and identify my recipes
    --- to neatly fit them into my existing structures,
    --- just to accomodate for a dozen recipes.
    if self.currentCategory_str == "Cooking" or all_b then
        if recipes_list == nil then
            recipes_list = {};
        end

        for _, recipe_ar in pairs(self.evolvedRecipeInstances_ht) do
            for _, recipe in pairs(recipe_ar) do
                recipes_list[recipe] = true;
            end
        end
    end
    if recipes_list == nil then return; end

    recipes_list = self:FilterRecipes(recipes_list);

    local i = 0;
    for k, _ in pairs(recipes_list) do
        i = i + 1;
        self.recipe_listbox:addItem(k.outputName_str, k);
        if selected_item and k == selected_item.item then
            self.recipe_listbox.selected = i;
        end
    end
end

function ISCraftingUI:UpdateAvailableItems()
    if not self.character then return end
    self.containerList = ArrayList.new();
    for i,v in ipairs(getPlayerInventory(self.playerNum).inventoryPane.inventoryPage.backpacks) do
        self.containerList:add(v.inventory);
    end
    for i,v in ipairs(getPlayerLoot(self.playerNum).inventoryPane.inventoryPage.backpacks) do
        self.containerList:add(v.inventory);
    end

    self.availableItems_ht = {};
    for i = 0, self.containerList:size() - 1 do
        local container = self.containerList:get(i);
        local inventory_items = container:getAllEval(function(a) return true end);
        for j = 0, inventory_items:size() - 1 do
            local item = inventory_items:get(j);
            local full_type = item:getFullType();

            if self.availableItems_ht[full_type] == nil then
                self.availableItems_ht[full_type] = {};
            end
            table.insert(self.availableItems_ht[full_type], item);
        end
    end
end

-- TODO: Could move this to UpdateAvailableItems.
function ISCraftingUI:UpdateEvolvedItems()
    --- As far as I can tell, the only way to check if an item is still nearby,
    --- is to iterate over all the items nearby and try to find said item.
    --- This is terribly unfortunate.

    -- evolved item stuff
    -- TODO: test not adding container list.

    local recipe_instance_ht = CDTools:ShallowCopy(self.evolvedRecipeInstances_ht);
    self.evolvedRecipeInstances_ht = {};
    for i = 0, self.containerList:size() - 1 do
        local container = self.containerList:get(i);
        local inventory_items = container:getAllEval(function(a) return true end);
        for j = 0, inventory_items:size() -1 do
            local item = inventory_items:get(j);
            local uid = item:getID();
            -- Already indexed, just add it back to the table
            if recipe_instance_ht[uid] then
                self.evolvedRecipeInstances_ht[uid] = recipe_instance_ht[uid];
            -- New item to index.
            else
                self.shouldUpdateFilter_b = true;
                local recipes = self:GetItemEvolvedRecipes(item);
                self.evolvedRecipeInstances_ht[uid] = recipes;
            end
        end
    end
end

function ISCraftingUI:UpdateRecipesAvailable()
    -- TODO: If performance proves to be an issue, try chunking this update.
    for _, list_item in pairs(self.recipe_listbox.items) do
        local recipe = list_item.item;
        recipe:UpdateAvailability(false);
        if recipe.availableChanged_b then
            self.shouldUpdateOrder_b = true;
        end
    end
end

function ISCraftingUI:UpdateSelectedRecipe()
    -- TODO: What does recipeListHasFocus do?
    local hasFocus = self.recipeListHasFocus;
    self.recipeListHasFocus = true;
    self.ingredientPanel:setVisible(false);

    if not self.recipe_listbox.items or #self.recipe_listbox.items == 0 or not self:GetListboxSelected(self.recipe_listbox) then return end

    local recipe = self:GetListboxSelected(self.recipe_listbox).item;
    if not recipe then return end

    self.recipeListHasFocus = hasFocus;
    self.ingredientPanel:setVisible(true)
    recipe:UpdateAvailability(true);
    if self.hasRenderedIngredients_b and not recipe.anyChange_b then
        return;
    end
    self.hasRenderedIngredients_b = true;
    self.ingredientPanel:clear();

    if recipe:IsType(CDRecipe) then
        self:UpdateIngredientsBasic(recipe);
    else
        self:UpdateIngredientsEvolved(recipe);
    end
end

function ISCraftingUI:UpdateIngredientsBasic(recipe)
    local sortedSources = {};
    for _, source in ipairs(recipe.sources_ar) do
        table.insert(sortedSources, source)
    end
    table.sort(sortedSources, function(a,b) return #a.items_ar == 1 and #b.items_ar > 1 end)

    for _, source in ipairs(sortedSources) do
        local available = {}
        local unavailable = {}

        for _, source_item in ipairs(source.items_ar) do
            if source_item.available_b then --recipe_types_available and (not recipe_types_available[source_item.fullType] or recipe_types_available[source_item.fullType] < source_item.source.requiredCount_i) then
                table.insert(available, source_item);
            else
                table.insert(unavailable, source_item);
            end
        end

        -- Drop down for "One of these items"
        if #source.items_ar > 1 then
            local dropdown = {}
            dropdown.recipe = recipe
            dropdown.texture = self.TreeExpanded
            dropdown.multipleHeader = true
            dropdown.available_b = #available > 0;
            self.ingredientPanel:addItem(getText("IGUI_CraftUI_OneOf"), dropdown)
        end

        -- What in blazes does this do?
        -- for j=1,#available do
        --     local item = available[j]
        --     self:removeExtraClothingItemsFromList(j+1, item, available)
        -- end
        -- for j=1,#available do
        --     local item = available[j]
        --     self:removeExtraClothingItemsFromList(1, item, unavailable)
        -- end
        -- for j=1,#unavailable do
        --     local item = unavailable[j]
        --     self:removeExtraClothingItemsFromList(j+1, item, unavailable)
        -- end

        table.sort(available, function(a, b) return not string.sort(a.name, b.name) end)
        table.sort(unavailable, function(a, b) return not string.sort(a.name, b.name) end)

        for _, item in ipairs(available) do
            if #source.items_ar > 1 and item.source.requiredCount_i > 1 then
                self.ingredientPanel:addItem(getText("IGUI_CraftUI_CountNumber", item.name, item.source.requiredCount_i), item)
            else
                self.ingredientPanel:addItem(item.name, item)
            end
        end

        for _, item in ipairs(unavailable) do
            if #source.items_ar > 1 and item.source.requiredCount_i > 1 then
                self.ingredientPanel:addItem(getText("IGUI_CraftUI_CountNumber", item.name, item.source.requiredCount_i), item)
            else
                self.ingredientPanel:addItem(item.name, item)
            end
        end
    end
    self.ingredientPanel.doDrawItem = ISCraftingUI.RenderNonEvolvedIngredient;
end

function ISCraftingUI:UpdateIngredientsEvolved(recipe)
    local available = {};
    local unavailable = {};

    for _, item in ipairs(recipe.evolvedItems_ar) do
        if item.available_b then
            table.insert(available, item);
        else
            table.insert(unavailable, item);
        end
    end
    -- TODO: Ingredient dropdown for food types, e.g. spices vs fruit.

    table.sort(available, function(a, b) return not string.sort(a.name, b.name) end)
    table.sort(unavailable, function(a, b) return not string.sort(a.name, b.name) end)

    for _, item in ipairs(available) do
        self.ingredientPanel:addItem(item.name, item)
    end

    for _, item in ipairs(unavailable) do
        self.ingredientPanel:addItem(item.name, item)
    end
    self.ingredientPanel.doDrawItem = ISCraftingUI.RenderEvolvedIngredient;
end

function ISCraftingUI:UpdateRecipeOrder()
    --- Some recipes have the same names but different outputs.
    --- Without this check, they roll over each other like a rainbow every frame.
    if not self.shouldUpdateOrder_b then
        return;
    end
    self.shouldUpdateOrder_b = false;
    local selected_item = self:GetListboxSelected(self.recipe_listbox);

    table.sort(self.recipe_listbox.items, CDIRecipe.SortFromListbox);

    if not selected_item then
        return;
    end

    local i = 0;
    for k, v in pairs(self.recipe_listbox.items) do
        i = i + 1;
        if v.item == selected_item.item then
            self.recipe_listbox.selected = i;
            return;
        end
    end
    -- Fallback; shouldn't happen.
    self.recipe_listbox.selected = -1;
end
-- #endregion

-- #region Render functions
function ISCraftingUI.RenderRecipeList(recipe_listbox, y, item, alt)
    local crafting_ui = recipe_listbox.parent;
    local recipe = item.item;
    local baseItemDY = 0
    -- TODO: I think this is causing evo recipes to have extra spacing
    if recipe.customRecipeName then
        baseItemDY = ISCraftingUI.fontHeightSmall
        item.height = recipe_listbox.itemheight + baseItemDY
    end

    if y + recipe_listbox:getYScroll() >= recipe_listbox.height then return y + item.height end
    if y + item.height + recipe_listbox:getYScroll() <= 0 then return y + item.height end

    local a = 0.9;
    if not recipe.available_b then
        a = 0.3;
    end

    recipe_listbox:drawRectBorder(0, (y), recipe_listbox:getWidth(), item.height - 1, a, recipe_listbox.borderColor.r, recipe_listbox.borderColor.g, recipe_listbox.borderColor.b);
    if recipe_listbox.selected == item.index then
        recipe_listbox:drawRect(0, (y), recipe_listbox:getWidth(), item.height - 1, 0.3, 0.7, 0.35, 0.15);
    end
    recipe_listbox:drawText(recipe.baseRecipe:getName(), 6, y + 2, 1, 1, 1, a, UIFont.Medium);
    -- if recipe.customRecipeName then
    --     recipe_listbox:drawText(recipe.customRecipeName, 6, y + 2 + recipe_listbox.fontHeightMedium, 1, 1, 1, a, UIFont.Small);
    -- end

    local textWidth = 0;
    if recipe.texture then
        local texWidth = recipe.texture:getWidthOrig();
        local texHeight = recipe.texture:getHeightOrig();
        if texWidth <= 32 and texHeight <= 32 then
            local tx = 6 + (32 - texWidth) / 2;
            local ty = y + 2 + crafting_ui.fontHeightMedium + baseItemDY + (32 - texHeight) / 2;
            recipe_listbox:drawTexture(recipe.texture, tx, ty, a, 1, 1, 1);
        else
            local tx = 6;
            local ty = y + 2 + crafting_ui.fontHeightMedium + baseItemDY;
            recipe_listbox:drawTextureScaledAspect(recipe.texture, 6, ty, 32, 32, a, 1, 1, 1);
        end
        -- local name = recipe.evolved and recipe.resultName or recipe.itemName
        local name = recipe.outputName_str;
        local ty = y + 2 + crafting_ui.fontHeightMedium + baseItemDY + (32 - crafting_ui.fontHeightSmall) / 2 - 2;
        recipe_listbox:drawText(name, texWidth + 20, ty, 1, 1, 1, a, UIFont.Small);
    end

    local star_icon = nil
    local favouriteAlpha = a
    -- Hovering recipe
    if item.index == recipe_listbox.mouseoverselected and not recipe_listbox:isMouseOverScrollBar() then
        if recipe_listbox:getMouseX() >= crafting_ui.favouriteXPos then
            star_icon = recipe.favourite and crafting_ui.favCheckedTex or crafting_ui.favNotCheckedTex
            favouriteAlpha = 0.9
        else
            star_icon = recipe.favourite and crafting_ui.favouriteStar or crafting_ui.favNotCheckedTex
            favouriteAlpha = recipe.favourite and a or 0.3
        end
    elseif recipe.favourite then
        star_icon = crafting_ui.favouriteStar
    end

    if star_icon then
        local ty = y + (item.height / 2 - star_icon:getHeight() / 2);
        recipe_listbox:drawTexture(star_icon, crafting_ui.favouriteXPos, ty, favouriteAlpha, 1, 1, 1);
    end

    return y + item.height;
end

function ISCraftingUI:RenderRecipeDetails(position, recipe)
    -- Render recipe preview
    self:drawRectBorder(position.x, position.y, 32 + 10, 32 + 10, 1.0, 1.0, 1.0, 1.0);
    if recipe.texture then
        if recipe.texture:getWidth() <= 32 and recipe.texture:getHeight() <= 32 then
            local newX = (32 - recipe.texture:getWidthOrig()) / 2;
            local newY = (32 - recipe.texture:getHeightOrig()) / 2;
            self:drawTexture(recipe.texture, position.x + 5 + newX, position.y + 5 + newY, 1, 1, 1, 1);
        else
            self:drawTextureScaledAspect(recipe.texture, position.x + 5, position.y + 5, 32, 32, 1, 1, 1, 1);
        end
    end

    local name = recipe.outputName_str;
    if recipe.evolved then
        name = recipe.outputName_str;
    end
    self:drawText(name, position.x + 32 + 15, position.y + ISCraftingUI.largeFontHeight, 1, 1, 1, 1, UIFont.Small);
    self:drawText(recipe.baseRecipe:getName() , position.x + 32 + 15, position.y, 1, 1, 1, 1, UIFont.Large);

    position.y = position.y + math.max(45, ISCraftingUI.largeFontHeight + ISCraftingUI.smallFontHeight);

    --- Originally this was an awful chain of if statements,
    --- with the code for both intertwined throughout.
    --- It was atrocious, especially towards the end of the block where,
    --- five times in a row, they checked "if not selected.evolved".
    --- Why would you do this?
    if recipe:IsType(CDEvolvedRecipe) then
        self:RenderEvolvedRecipeDetails(position, recipe);
    else
        self:RenderBasicRecipeDetails(position, recipe);
    end

    if recipe ~= self.selectedRecipe then
        self:UpdateSelectedRecipe();
        self.selectedRecipe = recipe;
    end
end

function ISCraftingUI:RenderBasicRecipeDetails(pos, recipe)
    self.craftOneButton:setVisible(true);
    self.craftAllButton:setVisible(true);
    -- self.debugGiveIngredientsButton:setVisible(getDebug());
    -- self.debugGiveIngredientsButton:setX(self.craftAllButton:getRight() + 5);
    -- self.debugGiveIngredientsButton:setY(pos.y);
    self:drawText(getText("IGUI_CraftUI_RequiredItems"), pos.x, pos.y, 1, 1, 1, 1, UIFont.Medium);

    pos.y = pos.y + ISCraftingUI.mediumFontHeight + 7;

    self.ingredientPanel:setX(pos.x + 15);
    self.ingredientPanel:setY(pos.y);
    self.ingredientPanel:setHeight(self.ingredientPanel.itemheight * 8);
    pos.y = self.ingredientPanel:getBottom();
    pos.y = pos.y + 4;

    self:RenderRecipeSkills(pos, recipe);

    -- Not sure what this does.
    if recipe.baseRecipe:getNearItem() then
        self:drawText(getText("IGUI_CraftUI_NearItem", recipe.baseRecipe:getNearItem()), pos.x, pos.y, 1, 1, 1, 1, UIFont.Medium);
        pos.y = pos.y + ISCraftingUI.mediumFontHeight;
    end

    -- Time to craft
    self:drawText(getText("IGUI_CraftUI_RequiredTime", recipe.baseRecipe:getTimeToMake()), pos.x, pos.y, 1, 1, 1, 1, UIFont.Medium);
    pos.y = pos.y + ISCraftingUI.mediumFontHeight;

    if recipe.baseRecipe:getTooltip() then
        pos.y = pos.y + 10;
        local tooltip = getText(recipe.baseRecipe:getTooltip());
        local numLines = 1;
        local p = string.find(tooltip, "\n");
        while p do
            numLines = numLines + 1;
            p = string.find(tooltip, "\n", p + 4);
        end
        self:drawText(tooltip, pos.x, pos.y, 1,1,1,1, UIFont.Small);
        pos.y = pos.y + ISCraftingUI.smallFontHeight * numLines;
    end

    self:RenderCraftButtons(pos, recipe);

    pos.y = pos.y + self.craftAllButton:getHeight() + 10;
end

function ISCraftingUI:RenderEvolvedRecipeDetails(pos, recipe)
    self.craftOneButton:setVisible(false);
    self.craftAllButton:setVisible(false);
    -- self.debugGiveIngredientsButton:setVisible(false);

    local imgW = 20;
    local imgH = 20;
    local imgPadX = 4;
    local dyText = (imgH - ISCraftingUI.smallFontHeight) / 2;
    if recipe.baseItem then
        self:drawText(getText("IGUI_CraftUI_BaseItem"), pos.x, pos.y, 1,1,1,1, UIFont.Medium);
        pos.y = pos.y + ISCraftingUI.mediumFontHeight;

        local offset = 15;
        local labelWidth = self.LabelDashWidth;
        local r,g,b = 1,1,1
        local r2,g2,b2 = 1,1,1;
        if not recipe.available_b then
            r,g,b = 0.54,0.54,0.54;
            r2,g2,b2 = 1,0.3,0.3;
        end

        self:drawText(self.LabelDash, pos.x + offset, pos.y + dyText, r,g,b,1, UIFont.Small);
        self:drawTextureScaledAspect(recipe.baseItem:getTex(), pos.x + offset + labelWidth + imgPadX, pos.y, imgW, imgH, 1,r2,b2,g2);
        self:drawText(recipe.baseItem:getDisplayName(), pos.x + offset + labelWidth + imgPadX + imgW + imgPadX, pos.y + dyText, r,g,b,1, UIFont.Small);
        pos.y = pos.y + ISCraftingUI.smallFontHeight + 7;

        if recipe.extraItems and #recipe.extraItems > 0 then
            self:drawText(getText("IGUI_CraftUI_AlreadyContainsItems"), pos.x, pos.y, 1,1,1,1, UIFont.Medium);
            pos.y = pos.y + ISCraftingUI.mediumFontHeight + 7;

            self:drawText(self.LabelDash, pos.x + offset, pos.y + dyText, r,g,b,1, UIFont.Small);
            local newX = pos.x + offset + labelWidth + imgPadX;

            for _, h in ipairs(recipe.extraItems) do
                self:drawTextureScaledAspect(h, newX, pos.y, imgW, imgH, g2,r2,b2,g2);
                newX = newX + 22;
            end

            if self.character and self.character:isKnownPoison(recipe.baseItem) and self.PoisonTexture then
                self:drawTexture(self.PoisonTexture, newX, pos.y + (imgH - self.PoisonTexture:getHeight()) / 2, 1,r2,g2,b2)
            end

            pos.y = pos.y + ISCraftingUI.mediumFontHeight + 7;
        elseif self.character and self.character:isKnownPoison(recipe.baseItem) and self.PoisonTexture then
            self:drawText(getText("IGUI_CraftUI_AlreadyContainsItems"), pos.x, pos.y, 1,1,1,1, UIFont.Medium);
            pos.y = pos.y + ISCraftingUI.mediumFontHeight + 7;

            self:drawText(self.LabelDash, pos.x + offset, pos.y + dyText, r,g,b,1, UIFont.Small);
            local newX = pos.x + offset + labelWidth + imgPadX;

            self:drawTexture(self.PoisonTexture, newX, pos.y + (imgH - self.PoisonTexture:getHeight()) / 2, 1,r2,g2,b2)

            pos.y = pos.y + ISCraftingUI.smallFontHeight + 7;
        end
    end

    self:drawText(getText("IGUI_CraftUI_ItemsToAdd"), pos.x, pos.y, 1,1,1,1, UIFont.Medium);
    pos.y = pos.y + ISCraftingUI.mediumFontHeight + 7;

    self.ingredientPanel:setX(pos.x + 15)
    self.ingredientPanel:setY(pos.y)
    self.ingredientPanel:setHeight(self.ingredientPanel.itemheight * 8)
    self.addIngredientButton:setX(self.ingredientPanel:getX());
    self.addIngredientButton:setY(self.ingredientPanel:getY() + self.ingredientPanel:getHeight() + 10);
    self.addIngredientButton:setVisible(true);

    local item = self:GetListboxSelected(self.ingredientPanel);
    if item and item.item.available_b then
        self.addIngredientButton.enable = true;
    else
        self.addIngredientButton.enable = false;
    end

    pos.y = self.ingredientPanel:getBottom()
end

function ISCraftingUI:RenderRecipeSkills(pos, recipe)
    if recipe.baseRecipe:getRequiredSkillCount() <= 0 then
        return;
    end

    self:drawText(getText("IGUI_CraftUI_RequiredSkills"), pos.x, pos.y, 1, 1, 1, 1, UIFont.Medium);
    pos.y = pos.y + ISCraftingUI.mediumFontHeight;
    for i=1,recipe.baseRecipe:getRequiredSkillCount() do
        local skill = recipe.baseRecipe:getRequiredSkill(i - 1);
        local perk = PerkFactory.getPerk(skill:getPerk());
        local playerLevel = self.character and self.character:getPerkLevel(skill:getPerk()) or 0
        local perkName = perk and perk:getName() or skill:getPerk():name()
        local text = " - " .. perkName .. ": " .. tostring(playerLevel) .. " / " .. tostring(skill:getLevel());
        local r, g, b = 1, 1, 1;
        if self.character and (playerLevel < skill:getLevel()) then
            g = 0;
            b = 0;
        end
        self:drawText(text, pos.x + 15, pos.y, r, g, b, 1, UIFont.Small);
        pos.y = pos.y + ISCraftingUI.smallFontHeight;
    end
    pos.y = pos.y + 4;
end

function ISCraftingUI:RenderCraftButtons(pos, recipe)
    pos.y = pos.y + 10
    self.craftOneButton:setX(pos.x);
    self.craftOneButton:setY(pos.y);
    self.craftOneButton.enable = recipe.available_b;

    self.craftAllButton:setX(self.craftOneButton:getX() + 5 + self.craftOneButton:getWidth());
    self.craftAllButton:setY(pos.y);
    self.craftAllButton.enable = recipe.available_b;
    local title = getText("IGUI_CraftUI_ButtonCraftAll");
    if self.craftAllButton.enable then
        local count = RecipeManager.getNumberOfTimesRecipeCanBeDone(recipe.baseRecipe, self.character, self.containerList, nil)
        if count > 1 then
            title = getText("IGUI_CraftUI_ButtonCraftAllCount", count)
        elseif count == 1 then
            self.craftAllButton.enable = false
        end
    end
    if title ~= self.craftAllButton:getTitle() then
        self.craftAllButton:setTitle(title)
        self.craftAllButton:setWidthToTitle()
    end

    -- self.debugGiveIngredientsButton:setX(self.craftAllButton:getRight() + 5)
    -- self.debugGiveIngredientsButton:setY(pos.y);  -- TODO: For some reason this button is misaligned.
end

function ISCraftingUI.RenderIngredient(ingredient_panel, y, item, alt)
    if item.item:IsType(CDEvolvedRecipe) then
        ISCraftingUI.RenderEvolvedIngredient(ingredient_panel, y, item, alt);
    else
        ISCraftingUI.RenderNonEvolvedIngredient(ingredient_panel, y, item, alt);
    end
end

function ISCraftingUI.RenderEvolvedIngredient(ingredient_panel, y, item, alt)
    if y + ingredient_panel:getYScroll() >= ingredient_panel.height then return y + ingredient_panel.itemheight end
    if y + ingredient_panel.itemheight + ingredient_panel:getYScroll() <= 0 then return y + ingredient_panel.itemheight end

    local a = 0.9;
    if not item.item.available_b then
        a = 0.3;
    end

    ingredient_panel:drawRectBorder(0, (y), ingredient_panel:getWidth(), ingredient_panel.itemheight - 1, a, ingredient_panel.borderColor.r, ingredient_panel.borderColor.g, ingredient_panel.borderColor.b);

    if ingredient_panel.selected == item.index then
        ingredient_panel:drawRect(0, (y), ingredient_panel:getWidth(), ingredient_panel.itemheight - 1, 0.3, 0.7, 0.35, 0.15);
    end

    local imgW = 20
    local imgH = 20
    ingredient_panel:drawText(item.text, 6 + imgW + 4, y + (item.height - ISCraftingUI.smallFontHeight) / 2, 1, 1, 1, a, ingredient_panel.font);

    if item.item.texture then
        local texWidth = item.item.texture:getWidth();
        local texHeight = item.item.texture:getHeight();
        ingredient_panel:drawTextureScaledAspect(item.item.texture, 6, y + (ingredient_panel.itemheight - imgH) / 2, 20, 20, a,1,1,1);
    end

    if item.item.poison then
        if ingredient_panel.PoisonTexture then
            local textW = getTextManager():MeasureStringX(ingredient_panel.font, item.text)
            ingredient_panel:drawTexture(ingredient_panel.PoisonTexture, 6 + imgW + 4 + textW + 6, y + (ingredient_panel.itemheight - ingredient_panel.PoisonTexture:getHeight()) / 2, a, 1, 1, 1)
        end
    end

    return y + ingredient_panel.itemheight;
end

function ISCraftingUI.RenderNonEvolvedIngredient(ingredient_panel, y, item, alt)
    if y + ingredient_panel:getYScroll() >= ingredient_panel.height then return y + ingredient_panel.itemheight end
    if y + ingredient_panel.itemheight + ingredient_panel:getYScroll() <= 0 then return y + ingredient_panel.itemheight end

    if not ingredient_panel.parent.recipeListHasFocus and ingredient_panel.selected == item.index then
        ingredient_panel:drawRectBorder(1, y, ingredient_panel:getWidth()-2, ingredient_panel.itemheight, 1.0, 0.5, 0.5, 0.5);
    end

    if item.item.multipleHeader then
        local r,g,b = 1,1,1
        if not item.item.available_b then
            r,g,b = 0.54,0.54,0.54
        end
        ingredient_panel:drawText(item.text, 12, y + 2, r, g, b, 1, ingredient_panel.font)
        ingredient_panel:drawTexture(item.item.texture, 4, y + (item.height - item.item.texture:getHeight()) / 2 - 2, 1,1,1,1)
    else
        local r,g,b;
        local r2,g2,b2,a2;
        -- TODO: These should be indented, but aren't for some reason.
        -- local typesAvailable = item.item.recipe.typesAvailable_hs;
        if item.item.available_b then --typesAvailable and (not typesAvailable[item.item.fullType] or typesAvailable[item.item.fullType] < item.item.source.requiredCount_i) then
            r,g,b = 1,1,1;
            r2,g2,b2,a2 = 1,1,1,0.9;
        else
            r,g,b = 0.54,0.54,0.54;
            r2,g2,b2,a2 = 1,1,1,0.3;
        end

        local imgW = 20
        local imgH = 20
        local dx = 6 + (item.item.multiple and 10 or 0)

        ingredient_panel:drawText(item.text, dx + imgW + 4, y + (item.height - ISCraftingUI.smallFontHeight) / 2, r, g, b, 1, ingredient_panel.font)

        if item.item.texture then
            local texWidth = item.item.texture:getWidth()
            local texHeight = item.item.texture:getHeight()
            ingredient_panel:drawTextureScaledAspect(item.item.texture, dx, y + (ingredient_panel.itemheight - imgH) / 2, 20, 20, a2,r2,g2,b2)
        end
    end

    return y + ingredient_panel.itemheight;
end
-- #endregion

-- #region Crafting
function ISCraftingUI:craftAll()
    self:craft(nil, true);
end

function ISCraftingUI:craft(button, all)
    self.craftInProgress = false
    local recipe = self.recipe_listbox.items[self.recipe_listbox.selected].item;
    if recipe.evolved then return; end
    -- TODO: Implement my logic for recipe validity.
    if not RecipeManager.IsRecipeValid(recipe.baseRecipe, self.character, nil, self.containerList) then
        print("CDBetterCrafting: Recipe marked as valid, but was actually invalid!");
        return;
    end
    if not getPlayer() then return; end

    local itemsUsed = self:transferItems();
    if #itemsUsed == 0 then
        self:Refresh();
        return;
    end
    local returnToContainer = {};
    local container = itemsUsed[1]:getContainer()
    if not recipe.baseRecipe:isCanBeDoneFromFloor() then
        container = self.character:getInventory()
        for _,item in ipairs(itemsUsed) do
            if item:getContainer() ~= self.character:getInventory() then
                table.insert(returnToContainer, item)
            end
        end
    end

    -- TODO: Look over ISCraftAction.
    local action = ISCraftAction:new(self.character, itemsUsed[1], recipe.baseRecipe:getTimeToMake(), recipe.baseRecipe, container, self.containerList)
    if all then
        action:setOnComplete(ISCraftingUI.onCraftComplete, self, action, recipe.baseRecipe, container, self.containerList)
    else
        action:setOnComplete(ISCraftingUI.Refresh, self)    -- keep a track of our current task because we'll refresh the list once it's done
    end
    ISTimedActionQueue.add(action);

    ISCraftingUI.ReturnItemsToOriginalContainer(self.character, returnToContainer)
end

function ISCraftingUI:debugGiveIngredients()
    local recipeListBox = self:getRecipeListBox()
    local selectedItem = recipeListBox.items[recipeListBox.selected].item
    if selectedItem.evolved then return end
    local recipe = selectedItem.recipe
    local items = {}
    local options = {}
    options.AvailableItemsAll = RecipeManager.getAvailableItemsAll(recipe, self.character, self:UpdateAvailableItems(), nil, nil)
    options.MaxItemsPerSource = 10
    options.NoDuplicateKeep = true
    RecipeUtils.CreateSourceItems(recipe, options, items)
    for _,item in ipairs(items) do
        self.character:getInventory():AddItem(item)
    end
end

function ISCraftingUI:transferItems()
    local result = {};
    local recipe = self.recipe_listbox.items[self.recipe_listbox.selected].item.baseRecipe;
    -- TODO: My own logic for getting items needed.
    local items = RecipeManager.getAvailableItemsNeeded(recipe, self.character, self.containerList, nil, nil);
    if items:isEmpty() then return result end;

    for i = 0, items:size() - 1 do
        local item = items:get(i);
        table.insert(result, item);
        if not recipe:isCanBeDoneFromFloor() then
            if item:getContainer() ~= self.character:getInventory() then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, item, item:getContainer(), self.character:getInventory(), nil));
            end
        end
    end
    return result;
end

function ISCraftingUI.ReturnItemsToOriginalContainer(playerObj, items)
    for _, item in ipairs(items) do
        if item:getContainer() ~= playerObj:getInventory() then
            local action = ISInventoryTransferAction:new(playerObj, item, playerObj:getInventory(), item:getContainer(), nil)
            action:setAllowMissingItems(true)
            ISTimedActionQueue.add(action)
        end
    end
end

-- TODO: Add double clicking
function ISCraftingUI:onDblClickIngredientListbox(data)
    if data and data.available then
        self:addItemInEvolvedRecipe(data)
    end
end

function ISCraftingUI:onAddRandomIngredient(button)
    self:addItemInEvolvedRecipe(button.list[ZombRand(1, #button.list+1)]);
end

function ISCraftingUI:onAddIngredient()
    local item = self:GetListboxSelected(self.ingredientPanel);
    if item and item.item.available_b then
        self:addItemInEvolvedRecipe(item.item);
    end
end

function ISCraftingUI:addItemInEvolvedRecipe(ingredient)
    local returnToContainer = {};
    local item_instance = ingredient:GetItem();
    local base_item = ingredient.recipe:GetBaseItem();
    if not item_instance or not base_item then return; end

    -- Get ingredient
    if not self.character:getInventory():contains(item_instance) then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, item_instance, item_instance:getContainer(), self.character:getInventory(), nil));
        table.insert(returnToContainer, item_instance)
    end

    -- Get recipe base
    if not self.character:getInventory():contains(base_item) then -- take the base item if it's not in our inventory
        ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, base_item, base_item:getContainer(), self.character:getInventory(), nil));
        table.insert(returnToContainer, base_item)
    end

    ISTimedActionQueue.add(ISAddItemInRecipe:new(self.character, ingredient.recipe.baseRecipe, base_item, item_instance, (70 - self.character:getPerkLevel(Perks.Cooking))));
    self.craftInProgress = true;
    ISCraftingUI.ReturnItemsToOriginalContainer(self.character, returnToContainer);
    -- self:Refresh();
end
-- #endregion

-- #region Tidying functions
function ISCraftingUI:FilterRecipes(recipe_hs)
    local name_filter = self.nameFilterEntry:getInternalText():trim():lower();
    local component_filter = self.componentFilterEntry:getInternalText():trim():lower();
    self.lastNameFilter_str = name_filter;
    self.lastComponentFilter_str = component_filter;
    if name_filter == "" and component_filter == "" then
        return recipe_hs;
    end

    local new_recipes = {};
    for recipe, _ in pairs(recipe_hs) do
        if name_filter ~= "" then
            if recipe.outputName_str:lower():contains(name_filter) then
                new_recipes[recipe] = true;
            end
        end
        if component_filter ~= "" then
            local found_ingredient = false;

            for _, source in pairs(recipe.sources_ar) do
                for _, item in pairs(source.items_ar) do
                    if item.name:lower():contains(component_filter) then
                        new_recipes[recipe] = true;
                        found_ingredient = true;
                        break;
                    end
                end
                if found_ingredient then
                    break;
                end
            end
        end
    end

    return new_recipes;
end

function ISCraftingUI:GetItemEvolvedRecipes(base_item)
    -- This indexes non-evolved items as an empty dictionary.
    -- This prevents us needing to call getEvolvedRecipe on an item we know isn't an evo.
    local recipes = {};

    if not base_item:getExtraItems() then
        return recipes;
    end

    -- TODO: What does the container list do here? why is it passed?
    local evo_recipes = RecipeManager.getEvolvedRecipe(base_item, self.character, self.containerList, false);
    if not evo_recipes or evo_recipes:size() <= 0 then
        return recipes;
    end


    -- One item, like a pot of water, can go to multiple recipes.
    for i = 0, evo_recipes:size() - 1 do
        local evo_recipe = evo_recipes:get(i);
        if not evo_recipe:isHidden() or base_item ~= evo_recipe:getBaseItem() then
            local cder = CDEvolvedRecipeInstance:New(base_item, evo_recipe);
            if cder then
                table.insert(recipes, cder);
            end
        end
    end

    return recipes;
end

function ISCraftingUI:AddCategory(category_name_internal)
    if self.categories_hs[category_name_internal] ~= nil then
        print("CDBetterCrafting: Tried to create a category that already exists!");
        return;
    end
    self.categories_hs[category_name_internal] = true;

    local cat_name = getTextOrNull("IGUI_CraftCategory_" .. category_name_internal);
    if cat_name == nil then
        cat_name = category_name_internal;
    end
    local cat = CDDummyView:new(cat_name, self);
    cat:initialise();
    self.panel:addView(cat_name, cat);
    cat.infoText = getText("UI_CraftingUI");
end

function ISCraftingUI:AddCDRecipe(cd_recipe)
    self.allRecipes_ht[cd_recipe.baseRecipe] = cd_recipe;
    if self.recipeCategories_ht[cd_recipe.category_str] == nil then
        --- This maintains the functionality of the base game,
        --- where categories only appear if you can craft something in them,
        --- where favourite and general are the first categories,
        --- and where the rest are random order
        self.recipeCategories_ht[cd_recipe.category_str] = {};
        self:AddCategory(cd_recipe.category_str);
    end
    self.recipeCategories_ht[cd_recipe.category_str][cd_recipe] = true;
end

-- TODO: would rather this be an extension for listbox
function ISCraftingUI:GetListboxSelected(listbox)
    if #listbox.items == 0 then return nil; end
    if #listbox.items < listbox.selected then return nil; end
    if listbox.selected < 1 then return nil; end
    return listbox.items[listbox.selected];
end
-- #endregion

-- #region Uncategorized
function ISCraftingUI:isWaterSource(item)
    return instanceof(item, "DrainableComboItem") and item:isWaterSource()-- and item:getDrainableUsesInt() >= count
end

--- Normally I rewrite functions, both to make them cleaner,
--- and to gain a better understanding of them.
--- This function is an enigma to me.
--- Thankfully, and in what I'm sure is a complete accident,
--- this is a rare function that is relatively sealed, only a couple class references.
--- I shall allow it to remain in its little radioactive sarcophagus.
function ISCraftingUI:getAvailableItemsType()
    local result = {};
    local recipe = self.recipe_listbox.items[self.recipe_listbox.selected].item.baseRecipe;
    local items = RecipeManager.getAvailableItemsAll(recipe, self.character, self.containerList, nil, nil);

    for i=0, recipe:getSource():size()-1 do
        local source = recipe:getSource():get(i);
        local sourceItemTypes = {};
        for k=1,source:getItems():size() do
            local sourceFullType = source:getItems():get(k-1);
            sourceItemTypes[sourceFullType] = true;
        end
        for x=0,items:size()-1 do
            local item = items:get(x)

            if sourceItemTypes["Water"] and self:isWaterSource(item, source:getCount()) then
                result["Water"] = (result["Water"] or 0) + item:getDrainableUsesInt()
            elseif sourceItemTypes[item:getFullType()] then
                local count = 1
                if not source:isDestroy() and item:IsDrainable() then
                    count = item:getDrainableUsesInt()
                end
                if not source:isDestroy() and instanceof(item, "Food") then
                    if source:getUse() > 0 then
                        count = -item:getHungerChange() * 100
                    end
                end
                result[item:getFullType()] = (result[item:getFullType()] or 0) + count;
            end
        end
        testb = true;
    end

    return result;
end

ISCraftingUI.sortByName = function(a,b)
    return string.sort(b.recipe:getName(), a.recipe:getName());
end

function ISCraftingUI:refreshTickBox()
    local recipeListBox = self:getRecipeListBox()
    local selectedItem = recipeListBox.items[recipeListBox.selected].item;
    self.tickBox.options = {};
    self.tickBox.optionCount = 1;
    for m,l in ipairs(selectedItem.multipleItems) do
        self.tickBox:addOption(l.name, nil, l.texture)
        if m == 1 then
            self.tickBox:setSelected(m, true)
        end
    end
end

function ISCraftingUI:isExtraClothingItemOf(item1, item2)
    local scriptItem = getScriptManager():FindItem(item1.fullType)
    if not scriptItem then
        return false
    end
    local extras = scriptItem:getClothingItemExtra()
    if not extras then
        return false
    end
    local moduleName = scriptItem:getModule():getName()
    for i=1,extras:size() do
        local extra = extras:get(i-1)
        local fullType = moduleDotType(moduleName, extra)
        if item2.fullType == fullType then
            return true
        end
    end
    return false
end

function ISCraftingUI:removeExtraClothingItemsFromList(index, item, itemList)
    for k=#itemList,index,-1 do
        local item2 = itemList[k]
        if self:isExtraClothingItemOf(item, item2) then
            table.remove(itemList, k)
        end
    end
end

function ISCraftingUI:sortList() -- sort list with items you can craft in first
    local availableList = {};
    local notAvailableList = {};
    for i,v in pairs(self.recipesList) do
        if not availableList[i] then
            availableList[i] = {};
            notAvailableList[i] = {};
        end
        for k,l in ipairs(v) do
            if l.available then
                table.insert(availableList[i], l);
            else
                table.insert(notAvailableList[i], l);
            end
        end
    end
    self.recipesList = {};
    for i,v in pairs(availableList) do
        table.sort(v, ISCraftingUI.sortByName);
        if not self.recipesList[i] then
            self.recipesList[i] = {};
        end
        for k,l in ipairs(v) do
		   self.recipesList[i][#self.recipesList[i]+1] = l;
        end
    end
    for i,v in pairs(notAvailableList) do
        table.sort(v, ISCraftingUI.sortByName);
        if not self.recipesList[i] then
            self.recipesList[i] = {};
        end
        for k,l in ipairs(v) do
			self.recipesList[i][#self.recipesList[i]+1] = l;
        end
    end
end

ISCraftingUI.toggleCraftingUI = function()
    local ui = getPlayerCraftingUI(0)
    if ui then
        if ui:getIsVisible() then
            ui:setVisible(false)
            ui:removeFromUIManager() -- avoid update() while hidden
        else
            ui:setVisible(true)
            ui:addToUIManager()
        end
    end
end

ISCraftingUI.onPressKey = function(key)
    if not MainScreen.instance or not MainScreen.instance.inGame or MainScreen.instance:getIsVisible() then
        return
    end
    if key == getCore():getKey("Crafting UI") then
        ISCraftingUI.toggleCraftingUI();
    end
end

function ISCraftingUI:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE or
            key == getCore():getKey("Crafting UI") or
            key == ISCraftingUI.upArrow or
            key == ISCraftingUI.downArrow or
            key == ISCraftingUI.leftCategory or
            key == ISCraftingUI.rightCategory or
            key == Keyboard.KEY_C or
            key == Keyboard.KEY_R or
            key == Keyboard.KEY_F
end

function ISCraftingUI:onKeyRelease(key)
    local ui = self
    if not ui.panel or not ui.panel.activeView then return; end
    if key == getCore():getKey("Crafting UI") then
        ISCraftingUI.toggleCraftingUI();
        return;
    end
    if key == Keyboard.KEY_ESCAPE then
        ISCraftingUI.toggleCraftingUI();
        return;
    end
    local self = ui.panel.activeView.view.recipes;
    if key == ISCraftingUI.upArrow then
        self.selected = self.selected - 1;
        if self.selected <= 0 then
            self.selected = self.count;
        end
    elseif key == ISCraftingUI.downArrow then
        self.selected = self.selected + 1;
        if self.selected > self.count then
            self.selected = 1;
        end
    end
    local viewIndex = ui.panel:getActiveViewIndex()
    local oldViewIndex = viewIndex
    if key == ISCraftingUI.leftCategory then
        if viewIndex == 1 then
            viewIndex = #ui.panel.viewList
        else
            viewIndex = viewIndex - 1
        end
    elseif key == ISCraftingUI.rightCategory then
        if viewIndex == #ui.panel.viewList then
            viewIndex = 1
        else
            viewIndex = viewIndex + 1
        end
    end
    if key == Keyboard.KEY_C then
        -- TODO: Add ingredient hotkey
        -- if ui.ingredientListbox:getIsVisible() then
            -- ui:onAddIngredient();
        -- elseif ui.craftOneButton.enable then
            -- ui:craft();
        -- end
    elseif key == Keyboard.KEY_R and ui.craftAllButton.enable then
        ui:craftAll();
    elseif key == Keyboard.KEY_F then
        ui.panel.activeView.view:addToFavorite(true);
    end
    if oldViewIndex ~= viewIndex then
        ui.panel:activateView(ui.panel.viewList[viewIndex].name)
    end
    -- TODO: Add this back in, whatever it does.
    -- ui.panel.activeView.view.recipes:ensureVisible(ui.panel.activeView.view.recipes.selected)
end

function ISCraftingUI:getFavoriteModDataString(recipe)
    local text = "craftingFavorite:" .. recipe:getOriginalname();
    if instanceof(recipe, "EvolvedRecipe") then
        text = text .. ':' .. recipe:getBaseItem()
        text = text .. ':' .. recipe:getResultItem()
    else
        for i=0,recipe:getSource():size()-1 do
            local source = recipe:getSource():get(i)
            for j=1,source:getItems():size() do
                text = text .. ':' .. source:getItems():get(j-1);
            end
        end
    end
    return text;
end

function ISCraftingUI:getFavoriteModDataLocalString(recipe) -- For backward compatibility only
    local text = "craftingFavorite:" .. recipe:getName();
    if instanceof(recipe, "EvolvedRecipe") then
        text = text .. ':' .. recipe:getBaseItem()
        text = text .. ':' .. recipe:getResultItem()
    else
        for i=0,recipe:getSource():size()-1 do
            local source = recipe:getSource():get(i)
            for j=1,source:getItems():size() do
                text = text .. ':' .. source:getItems():get(j-1);
            end
        end
    end
    return text;
end
ISCraftingUI.onKeyPressed = function (key)
    if key == getCore():getKey("Crafting UI") then
        if not ISCraftingUI.instance then
            ISCraftingUI.instance = ISCraftingUI:new(0,0,800,600,getPlayer());
            ISCraftingUI.instance:initialise();
            ISCraftingUI.instance:addToUIManager();
            ISCraftingUI.instance:setVisible(true);
        else
            ISCraftingUI.instance:setVisible(not ISCraftingUI.instance:getIsVisible());
        end
    end
end

ISCraftingUI.load = function()
    ISCraftingUI.instance = ISCraftingUI:new(0,0,800,600,nil);
    ISCraftingUI.instance:initialise();
    ISCraftingUI.instance:addToUIManager();
end

function ISCraftingUI:onResize()
    self.ingredientPanel:setWidth(self.width / 3)
    if self.catListButtons then
        for _,button in ipairs(self.catListButtons) do
            button:setX(self.ingredientPanel:getRight() + 10)
        end
    end
end

function ISCraftingUI:onCraftComplete(completedAction, recipe, container, containers)
    if not RecipeManager.IsRecipeValid(recipe, self.character, nil, containers) then return end
    local items = RecipeManager.getAvailableItemsNeeded(recipe, self.character, containers, nil, nil)
    if items:isEmpty() then
        self:Refresh()
        return
    end
    local previousAction = completedAction
    local returnToContainer = {};
    if not recipe:isCanBeDoneFromFloor() then
        for i=1,items:size() do
            local item = items:get(i-1)
            if item:getContainer() ~= self.character:getInventory() then
                local action = ISInventoryTransferAction:new(self.character, item, item:getContainer(), self.character:getInventory(), nil)
                ISTimedActionQueue.addAfter(previousAction, action)
                previousAction = action
                table.insert(returnToContainer, item)
            end
        end
    end
    local action = ISCraftAction:new(self.character, items:get(0), recipe:getTimeToMake(), recipe, container, containers)
    action:setOnComplete(ISCraftingUI.onCraftComplete, self, action, recipe, container, containers)
    ISTimedActionQueue.addAfter(previousAction, action)
    ISCraftingUI.ReturnItemsToOriginalContainer(self.character, returnToContainer)
end
-- #endregion

Events.OnCustomUIKey.Add(ISCraftingUI.onPressKey);
