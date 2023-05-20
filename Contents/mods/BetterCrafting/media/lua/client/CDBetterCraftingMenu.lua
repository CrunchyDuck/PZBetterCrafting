require "ISUI/ISCraftingUI"

-- Ability to search ingredients
-- Ability for recipes to queue subrecipes, e.g. opening a can to use in cooking
-- Group identical recipes.
-- Hide recipes functionality
-- really just take everything from Cataclysm.
-- Rename "general" to "uncategorized" - that's what it really is.

--- I will be using hungarian notation to make up for a lack of types.
--- Anything without a suffix is a java object, described in a comment. These are initialized as tables.
--- My suffixes are as follows:
--- ar - Array
--- arj - Java array/list
--- ht - Hash table/dictionary; Dictionaries will have their K/V types defined in comments.
--- hs - Hash set; In hash sets, the Value component is always true.

-- == Initialization == --
ISCraftingUI.allRecipes_hs = {};
ISCraftingUI.favourites_hs = {};
ISCraftingUI.recipes_ht = {};  -- K:string/V:CDRecipe
