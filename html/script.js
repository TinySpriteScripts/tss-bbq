const SlotCount = 5;  // Default number of slots, can be changed easily
const hideUI = true;

// Sample Ingredients
const Ingredients = {
  bread: { name: "Bread", icon: "./images/burgerbun.png", quantity: 10 },
  meat: { name: "Meat", icon: "./images/patty.png", quantity: 5 },
  tomato: { name: "Tomato", icon: "./images/tomato.png", quantity: 7 },
  lettuce: { name: "Lettuce", icon: "./images/lettuce.png", quantity: 8 },
  bacon: { name: "Bacon", icon: "./images/bacon.png", quantity: 8 },
  water: { name: "Water", icon: "./images/water.png", quantity: 8 },
  potato: { name: "Potato", icon: "./images/potato.png", quantity: 8 },
  fries: { name: "Fries", icon: "./images/fries.png", quantity: 8 },
};

// Sample Recipes
const Recipes = [
  {
    name: "Burger",
    icon: "./images/burger.png",
    ingredients: [
      { id: "bread", amount: 2 },
      { id: "meat", amount: 1 },
      { id: "tomato", amount: 1 },
      { id: "lettuce", amount: 2 },
    ],
  },
  {
    name: "Fries",
    icon: "./images/fries.png",
    ingredients: [
      { id: "potato", amount: 2 },
    ],
  },
  {
    name: "Bacon Sandwich",
    icon: "./images/bacon_sandwich.png",
    ingredients: [
      { id: "bread", amount: 2 },
      { id: "bacon", amount: 1 },
    ],
  },
];

const cookingContainer = document.getElementById("cookingContainer");
const slotsContainer = document.getElementById("cookingSlots");

// Populate Ingredients Panel
const ingredientsPanel = document.getElementById("ingredientsPanel");
Object.entries(Ingredients).forEach(([id, data]) => {
  const div = document.createElement("div");
  div.className = "ingredient";
  div.dataset.id = id;
  div.innerHTML = `
    <img src="${data.icon}" alt="${data.name}" />
    <span>${data.name} (${data.quantity})</span>
  `;
  div.addEventListener("click", () => addIngredientToSlot(id));
  ingredientsPanel.appendChild(div);
});

// Populate Recipes Panel
const recipesPanel = document.getElementById("recipesPanel");
Recipes.forEach((recipe, index) => {
  const div = document.createElement("div");
  div.className = "recipe";
  div.dataset.index = index;
  div.innerHTML = `
    <img src="${recipe.icon}" alt="${recipe.name}" />
    <div>
      <strong>${recipe.name}</strong><br/>
      ${recipe.ingredients.map(ing => `
          <div class="recipe-ingredient-icon" title="${Ingredients[ing.id].name} x${ing.amount}">
            <img src="${Ingredients[ing.id].icon}" alt="${Ingredients[ing.id].name}" />
            <span class="ingredient-amount">${ing.amount}</span>
          </div>
        `).join(' ')}

    </div>
  `;
  div.addEventListener("click", () => selectRecipe(index));
  recipesPanel.appendChild(div);
});

// Cooking Slots State
const cookingSlots = new Array(SlotCount).fill(null);

// Create slots dynamically based on SlotCount
for (let i = 0; i < SlotCount; i++) {
  const slotDiv = document.createElement("div");
  slotDiv.className = "slot";
  slotDiv.dataset.slot = i;
  slotsContainer.appendChild(slotDiv);
}

function updateSlots() {
  slotsContainer.querySelectorAll(".slot").forEach((slotDiv, i) => {
    slotDiv.innerHTML = "";
    if (cookingSlots[i]) {
      const { id, amount } = cookingSlots[i];
      const img = document.createElement("img");
      img.src = Ingredients[id].icon;
      slotDiv.appendChild(img);
      const qty = document.createElement("div");
      qty.className = "quantity";
      qty.textContent = amount;
      slotDiv.appendChild(qty);
    }
    slotDiv.onclick = () => removeSlot(i);
  });
}

function addIngredientToSlot(id) {
  // Count how many are already in slots
  const totalInSlots = cookingSlots
    .filter(s => s && s.id === id)
    .reduce((sum, s) => sum + s.amount, 0);

  if (totalInSlots >= Ingredients[id].quantity) {
    // Can't add more than available
    return;
  }

  // Check if already in a slot
  const existingIndex = cookingSlots.findIndex(s => s && s.id === id);
  if (existingIndex !== -1) {
    cookingSlots[existingIndex].amount += 1;
  } else {
    // Find first empty slot
    const index = cookingSlots.findIndex(s => s === null);
    if (index === -1) {
      setResultsDisplay("No empty slots available!");
      return;
    }

    cookingSlots[index] = { id, amount: 1 };
  }
  updateSlots();
}



function removeSlot(index) {
  cookingSlots[index] = null;
  updateSlots();
}

document.getElementById("craftButton").addEventListener("click", craft);

function craft() {
  // Loop through all recipes
  let matchedRecipe = null;

  for (const recipe of Recipes) {
    let valid = true;
    for (let i = 0; i < recipe.ingredients.length; i++) {
      const slot = cookingSlots[i];
      const expected = recipe.ingredients[i];
      if (!slot || slot.id !== expected.id || slot.amount !== expected.amount) {
        valid = false;
        break;
      }
    }
    // Also make sure there are no extra slots filled beyond the recipe length
    for (let i = recipe.ingredients.length; i < cookingSlots.length; i++) {
      if (cookingSlots[i] !== null) {
        valid = false;
        break;
      }
    }
    if (valid) {
      matchedRecipe = recipe;
      break;
    }
  }

  if (matchedRecipe) {
    setResultsDisplay(`Crafted ${matchedRecipe.name}!`);
    document.getElementById("resultDisplay").textContent = `Crafted ${matchedRecipe.name}!`;
    // Deduct ingredients
    matchedRecipe.ingredients.forEach(ing => {
      Ingredients[ing.id].quantity -= ing.amount;
    });
    // Clear slots
    for (let i = 0; i < SlotCount; i++) cookingSlots[i] = null;
    updateSlots();
    updateIngredientsPanel();
  } else {
    document.getElementById("resultDisplay").textContent = "No matching recipe.";
  }
}

let resultTimeout;

function setResultsDisplay(new_text) {
  clearTimeout(resultTimeout);
  const display = document.getElementById("resultDisplay");
  display.textContent = new_text;
  resultTimeout = setTimeout(() => {
    display.textContent = "";
  }, 2000);
}


function updateIngredientsPanel() {
  ingredientsPanel.innerHTML = "";
  Object.entries(Ingredients).forEach(([id, data]) => {
    const div = document.createElement("div");
    div.className = "ingredient";
    div.dataset.id = id;
    div.title = `${data.name} (${data.quantity})`; // Tooltip with name & quantity
    div.innerHTML = `
      <img src="${data.icon}" alt="${data.name}" />
    `;
    div.addEventListener("click", () => addIngredientToSlot(id));
    ingredientsPanel.appendChild(div);
  });
}


updateSlots();
updateIngredientsPanel();
if (hideUI) {
  cookingContainer.classList.add("hidden")
}
