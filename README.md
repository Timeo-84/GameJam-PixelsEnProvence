# 🌲 Le Gardien de la Sainte-Victoire

*Un jeu développé dans le cadre de la Game Jam "Pixels en Provence" - IUT d'Aix-Marseille.*

**Le Gardien de la Sainte-Victoire** est un jeu 2D de prévention et de gestion de crise environnementale. Incarnez un éco-garde, nettoyez les sentiers des déchets dangereux (attention à l'effet loupe du verre !) et luttez contre la propagation des incendies pour protéger la faune et la flore locales.

Ce projet répond directement aux **ODD 13** (Lutte contre les changements climatiques) et **ODD 15** (Vie terrestre). La mécanique de propagation du feu et d'intervention a été pensée pour refléter de manière crédible le comportement des incendies et l'urgence de l'action sur le terrain face aux feux de forêt.

---

## ⚙️ Prérequis

Pour ouvrir, tester et explorer le code de ce jeu, vous avez besoin du moteur **Godot 4**.
- Télécharger [Godot Engine 4.x (Version Standard)](https://godotengine.org/download)
- *Note : Godot est un exécutable autonome ultra-léger. Il ne nécessite pas d'installation complexe et tourne parfaitement sur Windows, macOS et Linux.*

---

## 🚀 Installation et Lancement (Windows & Mac)

### 1. Récupérer le projet
- **Option A (Via Git) :** Ouvrez votre terminal et tapez : 
  `git clone https://github.com/Timeo-84/GameJam-PixelsEnProvence.git`
- **Option B (Via ZIP) :** Cliquez sur le bouton vert **"Code"** en haut à droite de cette page, choisissez **"Download ZIP"**, puis extrayez le dossier sur votre ordinateur.

### 2. Importer dans Godot
1. Lancez **Godot Engine**.
2. Dans le gestionnaire de projets, cliquez sur le bouton **Importer** (Import).
3. Cliquez sur **Parcourir** (Browse) et allez chercher le fichier `project.godot` situé dans le dossier du jeu.
4. Cliquez sur **Importer et Éditer** (Import & Edit).

### 3. Tester le jeu
Une fois l'éditeur ouvert avec le projet chargé, appuyez simplement sur la touche **F5** (ou cliquez sur le triangle de lecture ▶️ en haut à droite de l'écran) pour lancer la scène principale et jouer !

---

## 🎮 Contrôles du jeu

- **Déplacements :** `Flèches directionnelles`
- **Interagir (Parler aux PNJ, recharger l'eau) :** Touche `E`
- **Ramasser un déchet :** Touche `F`
- **Utiliser l'extincteur à eau :** Maintenir `Espace` (ou Clic Gauche)

---

## 📁 Architecture du Code (Pour les curieux)

Le projet a été structuré de manière modulaire pour séparer la logique et le visuel :
- `/scenes` : Contient toutes les entités visuelles instanciables (`player.tscn`, `fire.tscn`, `npc.tscn`, etc.).
- `/scripts` : Logique du jeu en GDScript (fortement typé, utilisation massive des signaux pour éviter les dépendances dures).
- **Singletons (Autoloads) :** La gestion de la santé de la forêt, du score, et de l'eau est centralisée dans `game_state.gd`, tandis que les dialogues sont gérés dynamiquement par `dialogue_manager.gd`.

---

## 👥 Crédits
- **Développement & Narrative Design :** Timéo
- Créé pour la Game Jam du **L.A.B** (Laboratoire d'Aix-périmentation et de Bidouille).
