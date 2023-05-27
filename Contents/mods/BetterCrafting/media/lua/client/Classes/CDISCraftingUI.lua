-- TODO: Figure out customRecipeName
require "ISUI/ISCraftingUI"

ISCraftingUI = ISCollapsableWindow:derive("ISCraftingUI");
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

ISCraftingUI.allRecipes_hs = {};  -- hs[recipe]. Technically just all known recipes, but this is snappier.
ISCraftingUI.recipeCategories_ht = {};  -- ht[string, hs[recipe]].
ISCraftingUI.currentCategory_str = "General";
ISCraftingUI.categories_hs = {};  -- hs[str]. Used to name and track the tabs that go into panel.
ISCraftingUI.selectedRecipe = nil;


-- This should really be stored on an object somewhere, why does it need to be fetched and locally stored?
ISCraftingUI.fontHeightSmall = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight();
ISCraftingUI.fontHeightMedium = getTextManager():getFontFromEnum(UIFont.Medium):getLineHeight();
ISCraftingUI.favouriteXPos = 0;
ISCraftingUI.favouriteXPad = 20;
ISCraftingUI.favouriteStar = getTexture("media/ui/FavoriteStar.png");
ISCraftingUI.favCheckedTex = getTexture("media/ui/FavoriteStarChecked.png");
ISCraftingUI.favNotCheckedTex = getTexture("media/ui/FavoriteStarUnchecked.png");

--- Apologies for the indentation on functions.
--- I use [[]] as a substitute for C#'s #region, which I'm fond of in game dev.
--- The indentation is required for my text editor to collapse the contents.
-- [[ Constructors
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
        self.panel.onActivateView = ISCraftingUI.onActivateView;
        self.panel.target = self;
        self.panel:setEqualTabWidth(false)
        self:addChild(self.panel);
        self:UpdateRecipes();

        self.craftOneButton = ISButton:new(0, self.height-ISCraftingUI.bottomInfoHeight-20-15, 50,25,getText("IGUI_CraftUI_ButtonCraftOne"),self, ISCraftingUI.craft);
        self.craftOneButton:initialise()
        self:addChild(self.craftOneButton);

        self.craftAllButton = ISButton:new(0, self.height-ISCraftingUI.bottomInfoHeight-20-15, 50,25,getText("IGUI_CraftUI_ButtonCraftAll"),self, ISCraftingUI.craftAll);
        self.craftAllButton:initialise()
        self:addChild(self.craftAllButton);

        self.debugGiveIngredientsButton = ISButton:new(0, 0, 50, 25, "DBG: Give Ingredients", self, ISCraftingUI.debugGiveIngredients);
        self.debugGiveIngredientsButton:initialise();
        self:addChild(self.debugGiveIngredientsButton);

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
        self.ingredientPanel.doDrawItem = self.drawNonEvolvedIngredient
        self.ingredientPanel.drawBorder = true
        self.ingredientPanel:setVisible(false)
        self:addChild(self.ingredientPanel)

        self.ingredientListbox = ISScrollingListBox:new(1, 30, self.width / 3, self.height - (59 + ISCraftingUI.bottomInfoHeight));
        self.ingredientListbox:initialise();
        self.ingredientListbox:instantiate();
        self.ingredientListbox.itemheight = math.max(ISCraftingUI.smallFontHeight, 22);
        self.ingredientListbox.selected = 0;
        self.ingredientListbox.joypadParent = self;
        self.ingredientListbox.font = UIFont.NewSmall
        self.ingredientListbox.doDrawItem = self.drawEvolvedIngredient
        self.ingredientListbox:setOnMouseDoubleClick(self, self.onDblClickIngredientListbox);
        self.ingredientListbox.drawBorder = true
        self.ingredientListbox:setVisible(false)
        self:addChild(self.ingredientListbox);
        self.ingredientListbox.PoisonTexture = self.PoisonTexture

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

        local entryHgt = ISCraftingUI.fontHeightSmall + 2 * 2;
        self.filterLabel = ISLabel:new(x, y, entryHgt, text,1,1,1,1,UIFont.Small, true);
        self:addChild(self.filterLabel);
        x = x + getTextManager():MeasureStringX(UIFont.Small, text) + 9;

        local width = ((self.width/3) - getTextManager():MeasureStringX(UIFont.Small, text)) - 98;
        self.filterEntry = ISTextEntryBox:new("", x, y, width, ISCraftingUI.fontHeightSmall);
        self.filterEntry:initialise();
        self.filterEntry:instantiate();
        self.filterEntry:setText("");
        self.filterEntry:setClearButton(true);
        self:addChild(self.filterEntry);
        -- self.lastText = self.filterEntry:getInternalText();
        x = x + self.filterEntry.width + 5;
        
        -- AAAAAHAHAHAHAHAHAHAHHA. OOOHH! HHOOOOHOHHAHAHA!
        -- I'M SURE THEY DESIGNED THIS CLASS TO INFLICT HARM ON ALL WHO USE IT!
        self.filterAll = ISTickBox:new(x, y, 20, entryHgt, "", self, self.onFilterAll);
        self.filterAll:initialise();
        self.filterAll:addOption(getText("IGUI_FilterAll"));
        self.filterAll:setWidthToFit();
        self.filterAll:setVisible(true);
        self:addChild(self.filterAll);

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
        self.recipe_listbox.doDrawItem = self.DrawRecipes;
        -- self.recipe_listbox.onMouseDown = ISCraftingCategoryUI.onMouseDown_Recipes;
        -- self.recipe_listbox.onMouseDoubleClick = ISCraftingCategoryUI.onMouseDoubleClick_Recipes;
        self.recipe_listbox.joypadParent = self;
        self.recipe_listbox.drawBorder = false;
        self:addChild(self.recipe_listbox);
        
        -- Original code:
        -- While they subtract favPadX twice here, they end up adding the padding back in later.
        -- what??
        --local scrollBarWid = self.recipes:isVScrollBarVisible() and 13 or 0
        --return self.recipes:getWidth() - scrollBarWid - self.favPadX - self.favWidth - self.favPadX

        -- I'm not sure why they originally repositioned the star if the scroll bar was visible.
        -- It's not like it's perfectly calculated to fit the golden ratio or something.
        
        -- What the fuck is this? Is this lua's version of a ternary?
        -- o.favWidth = o.favouriteStar and o.favouriteStar:getWidth() or 13
        
        self.favouriteXPos = self.recipe_listbox:getWidth() - self.favouriteXPad - self.favouriteStar:getWidth();

        self:Refresh();
    end

    function ISCraftingUI:initialise()
        ISCollapsableWindow.initialise(self);
    end
-- ]]

-- [[ Events
    function ISCraftingUI:update()
        -- if self.craftInProgress then
        --     local currentAction = ISTimedActionQueue.getTimedActionQueue(self.character);
        --     if not currentAction or not currentAction.queue or not currentAction.queue[1] then
        --         self:Refresh();
        --         self.craftInProgress = false;
        --     end
        -- end
        -- if self.needRefreshIngredientPanel then
        --     self.needRefreshIngredientPanel = false
        --     self:refreshIngredientPanel()
        -- end
    end

    function ISCraftingUI:render()
        ISCollapsableWindow.render(self);
        if self.isCollapsed then return end

        local multipleItemEvolvedRecipes = {};
        self.addIngredientButton:setVisible(false);
        local resize_handle_height = self.resizable and self:resizeWidgetHeight() or 0
        self:drawRectBorder(0, 0, self:getWidth(), self:getHeight(), self.borderColor.a, self.borderColor.r,self.borderColor.g,self.borderColor.b);
        self.javaObject:DrawTextureScaledColor(nil, 0, self:getHeight() - resize_handle_height - ISCraftingUI.bottomInfoHeight, self:getWidth(), 1, self.borderColor.r, self.borderColor.g,self.borderColor.b,self.borderColor.a);

        local textWidth = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_CraftingUI_KnownRecipes", self.knownRecipes,self.totalRecipes))
        self:drawText(getText("IGUI_CraftingUI_KnownRecipes", self.knownRecipes,self.totalRecipes), self.width - textWidth - 5, self.panel:getY() + self.panel.tabHeight + 8, 1,1,1,1, UIFont.Small);
        
        local text = self.ingredientListbox:getIsVisible() and self.bottomInfoText2 or self.bottomInfoText1
        self.keysText:setName(text);
        local x = (self.width / 2) - (self.keysText.width / 2);
        self.keysText:setX(x);

        local position = {};
        position.x = self:getWidth() / 3 + 80;
        position.y = 110;
        local recipe = self.recipe_listbox.items[self.recipe_listbox.selected].item;
        self:RenderRecipeDetails(position, recipe);

        if not recipe.evolved then
            -- local now = getTimestampMs()
            -- if not self.refreshTypesAvailableMS or (self.refreshTypesAvailableMS + 500 < now) then
            --     self.refreshTypesAvailableMS = now
            --     local typesAvailable = self:getAvailableItemsType();
            --     self.needRefreshIngredientPanel = self.needRefreshIngredientPanel or areTablesDifferent(selectedItem.typesAvailable, typesAvailable);
            --     selectedItem.typesAvailable = typesAvailable;
            -- end
            self:getContainers();
            -- recipe.available = RecipeManager.IsRecipeValid(recipe.baseRecipe, self.character, nil, self.containerList);
            self.craftOneButton:setVisible(true);
            self.craftAllButton:setVisible(true);
            self.debugGiveIngredientsButton:setVisible(getDebug());

            self.debugGiveIngredientsButton:setX(self.craftAllButton:getRight() + 5)
            self.debugGiveIngredientsButton:setY(position.y);
        else
            self.craftOneButton:setVisible(false);
            self.craftAllButton:setVisible(false);
            self.debugGiveIngredientsButton:setVisible(false);
        end
        -- TODO: Implement more from render.
    end

    function ISCraftingUI.DrawRecipes(recipe_listbox, y, item, alt)
        local crafting_ui = recipe_listbox.parent;
        local recipe = item.item;
        local baseItemDY = 0
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
-- ]]

-- [[ Render functions
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
            name = recipe.resultName;
        end
        self:drawText(name, position.x + 32 + 15, position.y + ISCraftingUI.largeFontHeight, 1, 1, 1, 1, UIFont.Small);
        self:drawText(recipe.baseRecipe:getName() , position.x + 32 + 15, position.y, 1, 1, 1, 1, UIFont.Large);

        position.y = position.y + math.max(45, ISCraftingUI.largeFontHeight + ISCraftingUI.smallFontHeight);

        --- Originally this was an awful chain of if statements,
        --- with the code for both intertwined throughout.
        --- It was atrocious, especially towards the end of the block where,
        --- five times in a row, they checked "if not selected.evolved".
        --- Why would you do this?
        if recipe.evolved then
            self:RenderEvolvedRecipeDetails(position, recipe);
        else
            self:RenderBasicRecipeDetails(position, recipe);
        end

        if recipe ~= self.selectedRecipe then
            self:refreshIngredientPanel();
            self:refreshIngredientList();
            self.selectedRecipe = recipe;
        end
    end

    function ISCraftingUI:RenderBasicRecipeDetails(pos, recipe)
        -- I'm not sure what this does.
        --  if not selectedItem.evolved then
        --     local now = getTimestampMs()
        --     if not self.refreshTypesAvailableMS or (self.refreshTypesAvailableMS + 500 < now) then
        --         self.refreshTypesAvailableMS = now
        --         local typesAvailable = self:getAvailableItemsType();
        --         self.needRefreshIngredientPanel = self.needRefreshIngredientPanel or areTablesDifferent(selectedItem.typesAvailable, typesAvailable);
        --         selectedItem.typesAvailable = typesAvailable;
        --     end
        self.craftOneButton:setVisible(true);
        self.craftAllButton:setVisible(true);
        self.debugGiveIngredientsButton:setVisible(getDebug());

        self.debugGiveIngredientsButton:setX(self.craftAllButton:getRight() + 5);
        self.debugGiveIngredientsButton:setY(pos.y);
        self:drawText(getText("IGUI_CraftUI_RequiredItems"), pos.x, pos.y, 1, 1, 1, 1, UIFont.Medium);

        pos.y = pos.y + ISCraftingUI.mediumFontHeight + 7;

        self.ingredientPanel:setX(pos.x + 15);
        self.ingredientPanel:setY(pos.y);
        self.ingredientPanel:setHeight(self.ingredientListbox.itemheight * 8);
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

        self.debugGiveIngredientsButton:setX(self.craftAllButton:getRight() + 5)
        self.debugGiveIngredientsButton:setY(pos.y);  -- TODO: For some reason this button is misaligned.
    end

    function ISCraftingUI:RenderEvolvedRecipeDetails(position, recipe)
        self.craftOneButton:setVisible(false);
        self.craftAllButton:setVisible(false);
        self.debugGiveIngredientsButton:setVisible(false);

        -- if selectedItem.evolved and selectedItem.baseItem then
        --     self:drawText(getText("IGUI_CraftUI_BaseItem"), x, y, 1,1,1,1, UIFont.Medium);
        --     y = y + ISCraftingUI.mediumFontHeight;
        --     local offset = 15;
        --     local labelWidth = self.LabelDashWidth
        --     local r,g,b = 1,1,1
        --     local r2,g2,b2 = 1,1,1;
        --     if not selectedItem.available then
        --         r,g,b = 0.54,0.54,0.54
        --         r2,g2,b2 = 1,0.3,0.3;
        --     end
        --     self:drawText(self.LabelDash, x + offset, y + dyText, r,g,b,1, UIFont.Small);
        --     self:drawTextureScaledAspect(selectedItem.baseItem:getTex(), x + offset + labelWidth + imgPadX, y, imgW, imgH, 1,r2,b2,g2);
        --     self:drawText(selectedItem.baseItem:getDisplayName(), x + offset + labelWidth + imgPadX + imgW + imgPadX, y + dyText, r,g,b,1, UIFont.Small);
        --     y = y + ISCraftingUI.smallFontHeight + 7;

        --     if selectedItem.extraItems and #selectedItem.extraItems > 0 then
        --         self:drawText(getText("IGUI_CraftUI_AlreadyContainsItems"), x, y, 1,1,1,1, UIFont.Medium);
        --         y = y + ISCraftingUI.mediumFontHeight + 7;
        --         self:drawText(self.LabelDash, x + offset, y + dyText, r,g,b,1, UIFont.Small);
        --         local newX = x + offset + labelWidth + imgPadX;
        --         for g,h in ipairs(selectedItem.extraItems) do
        --             self:drawTextureScaledAspect(h, newX, y, imgW, imgH, g2,r2,b2,g2);
        --             newX = newX + 22;
        --         end
        --         if self.character and self.character:isKnownPoison(selectedItem.baseItem) and self.PoisonTexture then
        --             self:drawTexture(self.PoisonTexture, newX, y + (imgH - self.PoisonTexture:getHeight()) / 2, 1,r2,g2,b2)
        --         end
        --         y = y + ISCraftingUI.mediumFontHeight + 7;
        --     elseif self.character and self.character:isKnownPoison(selectedItem.baseItem) and self.PoisonTexture then
        --         self:drawText(getText("IGUI_CraftUI_AlreadyContainsItems"), x, y, 1,1,1,1, UIFont.Medium);
        --         y = y + ISCraftingUI.mediumFontHeight + 7;
        --         self:drawText(self.LabelDash, x + offset, y + dyText, r,g,b,1, UIFont.Small);
        --         local newX = x + offset + labelWidth + imgPadX;
        --         self:drawTexture(self.PoisonTexture, newX, y + (imgH - self.PoisonTexture:getHeight()) / 2, 1,r2,g2,b2)
        --         y = y + ISCraftingUI.smallFontHeight + 7;
        --     end
        -- end

        -- self:drawText(getText("IGUI_CraftUI_ItemsToAdd"), x, y, 1,1,1,1, UIFont.Medium);

        --y = y + ISCraftingUI.mediumFontHeight + 7;

        -- if selectedItem.evolved then
        --     self.ingredientListbox:setX(x + 15)
        --     self.ingredientListbox:setY(y)
        --     self.ingredientListbox:setHeight(self.ingredientListbox.itemheight * 8)
        --     self.addIngredientButton:setX(self.ingredientListbox:getX());
        --     self.addIngredientButton:setY(self.ingredientListbox:getY() + self.ingredientListbox:getHeight() + 10);
        --     self.addIngredientButton:setVisible(true);
        --     if selectedItem.available then
        --         self.addIngredientButton.enable = true;
        --     else
        --         self.addIngredientButton.enable = false;
        --     end
        --     local item = self.ingredientListbox.items[self.ingredientListbox.selected]
        --     if not item or not item.item.available then
        --         self.addIngredientButton.enable = false;
        --     else
        --         self.addIngredientButton.enable = true;
        --     end

        -- y = self.ingredientListbox:getBottom()
    end

    function ISCraftingUI:refreshIngredientPanel()
        local hasFocus = not self.recipeListHasFocus
        self.recipeListHasFocus = true
        self.ingredientPanel:setVisible(false)

        local recipeListbox = self:getRecipeListBox()
        if not recipeListbox.items or #recipeListbox.items == 0 or not recipeListbox.items[recipeListbox.selected] then return end
        local selectedItem = recipeListbox.items[recipeListbox.selected].item;
        if not selectedItem or selectedItem.evolved then return end

        selectedItem.typesAvailable = self:getAvailableItemsType()

        self.recipeListHasFocus = not hasFocus
        self.ingredientPanel:setVisible(true) 

        self.ingredientPanel:clear()
        
        -- Display single-item sources before multi-item sources
        local sortedSources = {}
        for _,source in ipairs(selectedItem.sources) do
            table.insert(sortedSources, source)
        end
        table.sort(sortedSources, function(a,b) return #a.items == 1 and #b.items > 1 end)

        for _,source in ipairs(sortedSources) do
            local available = {}
            local unavailable = {}

            for _,item in ipairs(source.items) do
                local data = {}
                data.selectedItem = selectedItem
                data.name = item.name
                data.texture = item.texture
                data.fullType = item.fullType
                data.count = item.source.requiredCount_i
                data.recipe = selectedItem.recipe
                data.multiple = #source.items > 1
                if selectedItem.typesAvailable and (not selectedItem.typesAvailable[item.fullType] or selectedItem.typesAvailable[item.fullType] < item.source.requiredCount_i) then
                    table.insert(unavailable, data)
                else
                    table.insert(available, data)
                end
            end
            table.sort(available, function(a,b) return not string.sort(a.name, b.name) end)
            table.sort(unavailable, function(a,b) return not string.sort(a.name, b.name) end)

            if #source.items > 1 then
                local data = {}
                data.selectedItem = selectedItem
                data.texture = self.TreeExpanded
                data.multipleHeader = true
                data.available = #available > 0
                self.ingredientPanel:addItem(getText("IGUI_CraftUI_OneOf"), data)
            end

            -- Hack for "Dismantle Digital Watch" and similar recipes.
            -- Recipe sources include both left-hand and right-hand versions of the same item.
            -- We only want to display one of them.
            ---[[
            for j=1,#available do
                local item = available[j]
                self:removeExtraClothingItemsFromList(j+1, item, available)
            end

            for j=1,#available do
                local item = available[j]
                self:removeExtraClothingItemsFromList(1, item, unavailable)
            end

            for j=1,#unavailable do
                local item = unavailable[j]
                self:removeExtraClothingItemsFromList(j+1, item, unavailable)
            end
            --]]

            for k,item in ipairs(available) do
                if #source.items > 1 and item.source.requiredCount_i > 1 then
                    self.ingredientPanel:addItem(getText("IGUI_CraftUI_CountNumber", item.name, item.source.requiredCount_i), item)
                else
                    self.ingredientPanel:addItem(item.name, item)
                end;
            end
            for k,item in ipairs(unavailable) do
                if #source.items > 1 and item.source.requiredCount_i > 1 then
                    self.ingredientPanel:addItem(getText("IGUI_CraftUI_CountNumber", item.name, item.source.requiredCount_i), item)
                else
                    self.ingredientPanel:addItem(item.name, item)
                end
            end
        end

        self.refreshTypesAvailableMS = getTimestampMs()

        self.ingredientPanel.doDrawItem = ISCraftingUI.drawNonEvolvedIngredient
    end
-- ]]

-- TODO: Update containerList
function ISCraftingUI:UpdateRecipes()
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
    self.recipeCategories_ht = {};
    local recipes = getAllRecipes();  -- Java array
    for i = 0, recipes:size() - 1 do
        local newItem = {};
        local recipe = recipes:get(i);
        if recipe:isHidden() or not self.character or (recipe:needToBeLearn() and not self.character:isRecipeKnown(recipe)) then

        else
            local r = CDRecipe:New(recipe, self.character, self.containerList);
            if self.recipeCategories_ht[r.category_str] == nil then
                self.recipeCategories_ht[r.category_str] = {};
            end
            self.recipeCategories_ht[r.category_str][r] = true;

            self.allRecipes_hs[r] = true;
        end
    end
    
    -- TODO: Index evolved recipes.
    -- TODO: Favourited recipes.

    self:UpdateCategories();
end

function ISCraftingUI:UpdateCategories()
    --- This maintains the functionality of the base game,
    --- where categories only appear if you can craft something in them,
    --- where favourite and general are the first categories,
    --- and where the rest are random order

    for name, _ in pairs(self.categories_hs) do
        self.panel:removeView(name);
    end
    self.categories_hs = {};

    -- TODO: Check "general" is the internal category names.
    self:AddCategory("Favorite");
    self:AddCategory("General");

    for category_name, _ in pairs(self.recipeCategories_ht) do
        -- No CONTINUE KEYWORD.
        if category_name ~= "Favorite" and category_name ~= "General" then
            self:AddCategory(category_name);
        end
    end
end

function ISCraftingUI:AddCategory(category_name_internal)
    if self.categories_hs[category_name_internal] ~= nil then
        print("CDCrafting ERROR: Tried to create a category that already exists!");
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

function ISCraftingUI:SetDisplayedRecipes(filter_str, all_b)
    self.recipe_listbox:clear();
    self.recipe_listbox:setScrollHeight(0);
    
    local list = nil;
    if all_b then
        list = self.allRecipes_hs;
    else
        list = self.recipeCategories_ht[self.currentCategory_str];
    end
    if list == nil then
        return;
    end

    for k, _ in pairs(list) do
        self.recipe_listbox:addItem(k.outputName_str, k);
    end

    -- TODO: Implement filter parsing.
    -- self.recipe_listbox.items = CDTools:ShallowCopy(list2);
    table.sort(self.recipe_listbox.items, CDRecipe.SortFromListbox);
end

function ISCraftingUI:Refresh()
    self:SetDisplayedRecipes("", false);-- TODO: This checkbox doesn't work. self.filterAll:isSelected(1));
    if true then return end;
    local recipeListBox = self:getRecipeListBox();
    local selectedItem = recipeListBox.items[recipeListBox.selected];
    if selectedItem then selectedItem = selectedItem.item.recipe end
    local selectedView = self.panel.activeView.name;
    self:getContainers();
    self:populateRecipesList();
    self:sortList();
    for i=#self.categories,1,-1 do
        local categoryUI = self.categories[i];
        local found = false;
        for j=1,#self.recipesListH do
            if self.recipesListH[j] == categoryUI.category then
                found = true;
                break;
            end
        end
        if not found then
            self.panel:removeView(categoryUI);
            table.remove(self.categories, i);
        else
            categoryUI:filter();
        end
    end
    self.panel:activateView(selectedView);

    if selectedItem then
        for i,item in ipairs(recipeListBox.items) do
            if item.item.recipe == selectedItem then
                recipeListBox.selected = i;
                break;
            end
        end
    end
    local k
    for k = 1 , #self.recipesListH, 1 do
        local i = self.recipesListH[k]
        local v = self.recipesList[i]
        local found = false;
        for k,l in ipairs(self.categories) do
            if i == l.category then
                found = true;
                break;
            end
        end
        if not found then
            -- local cat1 = ISCraftingCategoryUI:new(0, 0, self.width, self.panel.height - self.panel.tabHeight, self);
            -- cat1:initialise();
            -- local catName = getTextOrNull("IGUI_CraftCategory_"..i) or i
            -- self.panel:addView(catName, cat1);
            -- cat1.infoText = getText("UI_CraftingUI");
            -- cat1.parent = self;
            -- cat1.category = i;
            -- for s,d in ipairs(v) do
            --     cat1.recipes:addItem(s,d);
            -- end
            -- table.insert(self.categories, cat1);
        end
    end
    if #recipeListBox.items == 0 then
        self.panel:activateView(getText("IGUI_CraftCategory_General"));
    end
    self:refreshIngredientList()
end

function ISCraftingUI:isWaterSource(item, count)
    return instanceof(item, "DrainableComboItem") and item:isWaterSource() and item:getDrainableUsesInt() >= count
end

function ISCraftingUI:transferItems()
    local result = {}
    local recipeListBox = self:getRecipeListBox()
    local recipe = recipeListBox.items[recipeListBox.selected].item.recipe;
    local items = RecipeManager.getAvailableItemsNeeded(recipe, self.character, self.containerList, nil, nil);
    if items:isEmpty() then return result end;
    for i=1,items:size() do
        local item = items:get(i-1)
        table.insert(result, item)
        if not recipe:isCanBeDoneFromFloor() then
            if item:getContainer() ~= self.character:getInventory() then
                ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, item, item:getContainer(), self.character:getInventory(), nil));
            end
        end
    end
    return result
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

function ISCraftingUI:getContainers()
    if not self.character then return end
    self.containerList = ArrayList.new();
    for i,v in ipairs(getPlayerInventory(self.playerNum).inventoryPane.inventoryPage.backpacks) do
        self.containerList:add(v.inventory);
    end
    for i,v in ipairs(getPlayerLoot(self.playerNum).inventoryPane.inventoryPage.backpacks) do
        self.containerList:add(v.inventory);
    end
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

function ISCraftingUI:drawNonEvolvedIngredient(y, item, alt)
    if y + self:getYScroll() >= self.height then return y + self.itemheight end
    if y + self.itemheight + self:getYScroll() <= 0 then return y + self.itemheight end

    if not self.parent.recipeListHasFocus and self.selected == item.index then
        self:drawRectBorder(1, y, self:getWidth()-2, self.itemheight, 1.0, 0.5, 0.5, 0.5);
    end

    if item.item.multipleHeader then
        local r,g,b = 1,1,1
        if not item.item.available then
            r,g,b = 0.54,0.54,0.54
        end
        self:drawText(item.text, 12, y + 2, r, g, b, 1, self.font)
        self:drawTexture(item.item.texture, 4, y + (item.height - item.item.texture:getHeight()) / 2 - 2, 1,1,1,1)
    else
        local r,g,b;
        local r2,g2,b2,a2;
        local typesAvailable = item.item.recipe.typesAvailable_hs;
        if typesAvailable and (not typesAvailable[item.item.fullType] or typesAvailable[item.item.fullType] < item.item.source.requiredCount_i) then
            r,g,b = 0.54,0.54,0.54;
            r2,g2,b2,a2 = 1,1,1,0.3;
        else
            r,g,b = 1,1,1;
            r2,g2,b2,a2 = 1,1,1,0.9;
        end

        local imgW = 20
        local imgH = 20
        local dx = 6 + (item.item.multiple and 10 or 0)
        
        self:drawText(item.text, dx + imgW + 4, y + (item.height - ISCraftingUI.smallFontHeight) / 2, r, g, b, 1, self.font)
        
        if item.item.texture then
            local texWidth = item.item.texture:getWidth()
            local texHeight = item.item.texture:getHeight()
            self:drawTextureScaledAspect(item.item.texture, dx, y + (self.itemheight - imgH) / 2, 20, 20, a2,r2,g2,b2)
        end
    end

    return y + self.itemheight;
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

function ISCraftingUI:refreshIngredientPanel()
    local hasFocus = self.recipeListHasFocus;
    self.recipeListHasFocus = true;
    self.ingredientPanel:setVisible(false);

    -- Should something be getting displayed?
    if not self.recipe_listbox.items or #self.recipe_listbox.items == 0 or not self.recipe_listbox.items[self.recipe_listbox.selected] then return end
    local recipe = self.recipe_listbox.items[self.recipe_listbox.selected].item;
    if not recipe or recipe.evolved then return end

    self.recipeListHasFocus = hasFocus;
    self.ingredientPanel:setVisible(true) 

    recipe.typesAvailable_hs = self:getAvailableItemsType();
    self.ingredientPanel:clear()
    local sortedSources = {}
    for _, source in ipairs(recipe.sources_ar) do
        table.insert(sortedSources, source)
    end
    table.sort(sortedSources, function(a,b) return #a.items_ar == 1 and #b.items_ar > 1 end)

    for _, source in ipairs(sortedSources) do
        local available = {}
        local unavailable = {}

        for _, source_item in ipairs(source.items_ar) do
            if source_item == nil then
            end
            if recipe_types_available and (not recipe_types_available[source_item.fullType] or recipe_types_available[source_item.fullType] < source_item.source.requiredCount_i) then
                table.insert(unavailable, source_item);
            else
                table.insert(available, source_item);
            end
        end

        -- Drop down for "One of these items"
        if #source.items_ar > 1 then
            local dropdown = {}
            dropdown.recipe = recipe
            dropdown.texture = self.TreeExpanded
            dropdown.multipleHeader = true
            dropdown.available = #available > 0;
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

    self.refreshTypesAvailableMS = getTimestampMs();
    self.ingredientPanel.doDrawItem = ISCraftingUI.drawNonEvolvedIngredient;
end

function ISCraftingUI:drawEvolvedIngredient(y, item, alt)
    if y + self:getYScroll() >= self.height then return y + self.itemheight end
    if y + self.itemheight + self:getYScroll() <= 0 then return y + self.itemheight end

    local a = 0.9;
    if not item.item.available then
        a = 0.3;
    end

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight - 1, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight - 1, 0.3, 0.7, 0.35, 0.15);
    end

    local imgW = 20
    local imgH = 20
    self:drawText(item.text, 6 + imgW + 4, y + (item.height - ISCraftingUI.smallFontHeight) / 2, 1, 1, 1, a, self.font);

    if item.item.texture then
        local texWidth = item.item.texture:getWidth();
        local texHeight = item.item.texture:getHeight();
        self:drawTextureScaledAspect(item.item.texture, 6, y + (self.itemheight - imgH) / 2, 20, 20, a,1,1,1);
    end

    if item.item.poison then
        if self.PoisonTexture then
            local textW = getTextManager():MeasureStringX(self.font, item.text)
            self:drawTexture(self.PoisonTexture, 6 + imgW + 4 + textW + 6, y + (self.itemheight - self.PoisonTexture:getHeight()) / 2, a, 1, 1, 1)
        end
    end
    
    return y + self.itemheight;
end

function ISCraftingUI:onDblClickIngredientListbox(data)
    if data and data.available then
        self:addItemInEvolvedRecipe(data)
    end
end

function ISCraftingUI:onAddRandomIngredient(button)
    self:addItemInEvolvedRecipe(button.list[ZombRand(1, #button.list+1)]);
end

function ISCraftingUI:onAddIngredient()
    local item = self.ingredientListbox.items[self.ingredientListbox.selected]
    if item and item.item.available then
        self:addItemInEvolvedRecipe(item.item);
    end
end

function ISCraftingUI:refreshIngredientList()
    if true then return end;  -- TODO: Figure out this.
    if not self.catListButtons then self.catListButtons = {}; end
    for i,v in ipairs(self.catListButtons) do
        v:setVisible(false);
        self:removeChild(v);
    end
    self.catListButtons = {};
    local hasFocus = not self.recipeListHasFocus
    self.recipeListHasFocus = true

    self.ingredientListbox:setVisible(false)

    local recipeListbox = self:getRecipeListBox()
    if not recipeListbox.items or #recipeListbox.items == 0 or not recipeListbox.items[recipeListbox.selected] then return end
    local selectedItem = recipeListbox.items[recipeListbox.selected].item;
    if not selectedItem or not selectedItem.evolved then return end

    self.recipeListHasFocus = not hasFocus
    self.ingredientListbox:setVisible(true)

    local available = {}
    local unavailable = {}
    for k,item in ipairs(selectedItem.items) do
        local data = {}
        data.available = item.available
        data.name = item.name
        data.texture = item.texture
        data.item = item.itemToAdd
        data.baseItem = selectedItem.baseItem
        data.recipe = selectedItem.recipe
        data.poison = item.poison
        if instanceof(item.itemToAdd, "Food") then
            if not data.recipe:needToBeCooked(item.itemToAdd) then
                item.available = false;
                data.available = false;
            end
            if item.itemToAdd:isFrozen() and (not data.recipe:isAllowFrozenItem()) then
                item.available = false;
                data.available = false;
            end
        end
        if item.available then
            table.insert(available, data)
        else
            table.insert(unavailable, data)
        end
    end
    table.sort(available, function(a,b) return not string.sort(a.name, b.name) end)
    table.sort(unavailable, function(a,b) return not string.sort(a.name, b.name) end)
    
    self.ingredientListbox:clear()
    self.catList = {};
    for k,item in ipairs(available) do
        self.ingredientListbox:addItem(item.name, item)
        local foodType = item.item:IsFood() and item.item:getFoodType()
        if foodType then
            if not self.catList[foodType] then self.catList[foodType] = {}; end
            table.insert(self.catList[foodType], item);
        end
    end
    for k,item in ipairs(unavailable) do
        self.ingredientListbox:addItem(item.name, item)
    end
    
    local y = self.ingredientListbox:getY();
    for i,v in pairs(self.catList) do
        local button = ISButton:new(self.ingredientListbox:getX() + self.ingredientListbox:getWidth() + 10 , y ,50,20,getText("ContextMenu_AddRandom", getText("ContextMenu_FoodType_"..i)), self, ISCraftingUI.onAddRandomIngredient);
        button.list = self.catList[i];
        button:initialise()
        self:addChild(button);
        table.insert(self.catListButtons, button);
        y = y + 25;
    end
end

function ISCraftingUI:onActivateView()
    local recipeListBox = self:getRecipeListBox()
    recipeListBox:ensureVisible(recipeListBox.selected);
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
        if ui.ingredientListbox:getIsVisible() then
            ui:onAddIngredient();
        elseif ui.craftOneButton.enable then
            ui:craft();
        end
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
    self.ingredientListbox:setWidth(self.width / 3)
    if self.catListButtons then
        for _,button in ipairs(self.catListButtons) do
            button:setX(self.ingredientListbox:getRight() + 10)
        end
    end
end

function ISCraftingUI:addItemInEvolvedRecipe(button)
        local returnToContainer = {};
        if not self.character:getInventory():contains(button.item) then -- take the item if it's not in our inventory
            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, button.item, button.item:getContainer(), self.character:getInventory(), nil));
            table.insert(returnToContainer, button.item)
        end
        if not self.character:getInventory():contains(button.baseItem) then -- take the base item if it's not in our inventory
            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, button.baseItem, button.baseItem:getContainer(), self.character:getInventory(), nil));
            table.insert(returnToContainer, button.baseItem)
        end
        ISTimedActionQueue.add(ISAddItemInRecipe:new(self.character, button.recipe, button.baseItem, button.item, (70 - self.character:getPerkLevel(Perks.Cooking))));
        self.craftInProgress = true;
        ISCraftingUI.ReturnItemsToOriginalContainer(self.character, returnToContainer);
    self:Refresh();
end

function ISCraftingUI:craftAll()
    self:craft(nil, true);
end

function ISCraftingUI:craft(button, all)
    self.craftInProgress = false
    local recipeListBox = self:getRecipeListBox()
    local selectedItem = recipeListBox.items[recipeListBox.selected].item;
    if selectedItem.evolved then return; end
    if not RecipeManager.IsRecipeValid(selectedItem.recipe, self.character, nil, self.containerList) then return; end

    if not getPlayer() then return; end
    local itemsUsed = self:transferItems();
    if #itemsUsed == 0 then
        self:Refresh();
        return
    end
    local returnToContainer = {};
    local container = itemsUsed[1]:getContainer()
    if not selectedItem.recipe:isCanBeDoneFromFloor() then
        container = self.character:getInventory()
        for _,item in ipairs(itemsUsed) do
            if item:getContainer() ~= self.character:getInventory() then
                table.insert(returnToContainer, item)
            end
        end
    end

    local action = ISCraftAction:new(self.character, itemsUsed[1], selectedItem.recipe:getTimeToMake(), selectedItem.recipe, container, self.containerList)
    if all then
        action:setOnComplete(ISCraftingUI.onCraftComplete, self, action, selectedItem.recipe, container, self.containerList)
    else
        action:setOnComplete(ISCraftingUI.Refresh, self)    -- keep a track of our current task because we'll refresh the list once it's done
    end
    ISTimedActionQueue.add(action);

    ISCraftingUI.ReturnItemsToOriginalContainer(self.character, returnToContainer)

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

function ISCraftingUI.ReturnItemsToOriginalContainer(playerObj, items)
    for _,item in ipairs(items) do
        if item:getContainer() ~= playerObj:getInventory() then
            local action = ISInventoryTransferAction:new(playerObj, item, playerObj:getInventory(), item:getContainer(), nil)
            action:setAllowMissingItems(true)
            ISTimedActionQueue.add(action)
        end
    end
end

function ISCraftingUI:GetItemInstance(type)
    if not self.ItemInstances then self.ItemInstances = {} end
    local item = self.ItemInstances[type]
    if not item then
        item = InventoryItemFactory.CreateItem(type)
        if item then
            self.ItemInstances[type] = item
            self.ItemInstances[item:getFullType()] = item
        end
    end
    return item
end

function ISCraftingUI:onGainJoypadFocus(joypadData)
    self.drawJoypadFocus = true
end

function ISCraftingUI:onJoypadDown(button)
    if button == Joypad.AButton then
        if self.ingredientListbox:getIsVisible() and not self.recipeListHasFocus then
            local item = self.ingredientListbox.items[self.ingredientListbox.selected]
            if item and item.item.available then
                self:addItemInEvolvedRecipe(item.item)
            end
        elseif self.craftOneButton.enable then
            self:craft()
        end
    end
    if button == Joypad.BButton then
        self:setVisible(false)
        setJoypadFocus(self.playerNum, nil)
    end
    if button == Joypad.XButton then
        if self.craftAllButton.enable then
            self:craftAll()
        end
    end
    if button == Joypad.YButton then
        self.panel.activeView.view:addToFavorite(true);
    end
    if button == Joypad.LBumper or button == Joypad.RBumper then
        local viewIndex = self.panel:getActiveViewIndex()
        if button == Joypad.LBumper then
            if viewIndex == 1 then
                viewIndex = #self.panel.viewList
            else
                viewIndex = viewIndex - 1
            end
        elseif button == Joypad.RBumper then
            if viewIndex == #self.panel.viewList then
                viewIndex = 1
            else
                viewIndex = viewIndex + 1
            end
        end
        self.panel:activateView(self.panel.viewList[viewIndex].name)
        local recipeListBox = self:getRecipeListBox()
        recipeListBox:ensureVisible(recipeListBox.selected)
    end
end

function ISCraftingUI:onJoypadDirUp()
    if self.recipeListHasFocus then
        self:getRecipeListBox():onJoypadDirUp()
    elseif self.ingredientPanel:getIsVisible() then
        self.ingredientPanel:onJoypadDirUp()
    elseif self.ingredientListbox:getIsVisible() then
        self.ingredientListbox:onJoypadDirUp()
    end
end

function ISCraftingUI:onJoypadDirDown()
    if self.recipeListHasFocus then
        self:getRecipeListBox():onJoypadDirDown()
    elseif self.ingredientPanel:getIsVisible() then
        self.ingredientPanel:onJoypadDirDown()
    elseif self.ingredientListbox:getIsVisible() then
        self.ingredientListbox:onJoypadDirDown()
    end
end

function ISCraftingUI:onJoypadDirLeft()
    self.recipeListHasFocus = true
end

function ISCraftingUI:onJoypadDirRight()
    if self.recipeListHasFocus and self.ingredientPanel:getIsVisible() then
        self.recipeListHasFocus = false
    elseif self.recipeListHasFocus and self.ingredientListbox:getIsVisible() then
        self.recipeListHasFocus = false
    end
end

function ISCraftingUI:debugGiveIngredients()
    local recipeListBox = self:getRecipeListBox()
    local selectedItem = recipeListBox.items[recipeListBox.selected].item
    if selectedItem.evolved then return end
    local recipe = selectedItem.recipe
    local items = {}
    local options = {}
    options.AvailableItemsAll = RecipeManager.getAvailableItemsAll(recipe, self.character, self:getContainers(), nil, nil)
    options.MaxItemsPerSource = 10
    options.NoDuplicateKeep = true
    RecipeUtils.CreateSourceItems(recipe, options, items)
    for _,item in ipairs(items) do
        self.character:getInventory():AddItem(item)
    end
end

Events.OnCustomUIKey.Add(ISCraftingUI.onPressKey);
