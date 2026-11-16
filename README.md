# Resile

**resile** (verb): to spring back; to recoil.

A top-down ricochet shooter made in Godot 4 for a game jam with the theme **"bounce back."**

You play a janitor blob who has just been fired and left behind on a cargo spaceship full of aliens. All you have is a cleaning laser, and it only works after it bounces off a wall.


<img width="1710" height="912" alt="image" src="https://github.com/user-attachments/assets/6b67583c-5ae0-4bd3-a6b9-00d6a5edd5a4" />

**Play it:** https://nirvith.itch.io/resile

## Story

The boss fires you. Seconds later, aliens board the ship. The crew takes the escape pods, and the boss takes the last one: "You're on your own. Don't scratch the floors."

Between waves he radios in from his pod, first to insult you and later to beg you to save his ship. Whether you go back to your desk on Monday is up to you.

## How to play

| Action | Control |
|---|---|
| Move | W A S D |
| Aim | Mouse |
| Fire | Left click |

### The rules

- **Bolts only count after a bounce.** A fresh bolt is faint and harmless. After its first wall bounce it turns live.
- **Live bolts hurt everyone, including you.** Watch your own ricochets.
- **Bolts get stronger as they bounce.** Each bounce makes a bolt faster and bigger, and after two bounces it pierces through enemies. A bolt disappears after its third bounce.
- **Your body is your health.** The blob is made of 8 cells. Every hit knocks one off and sends it flying across the room.
- **Pull yourself back together.** Run over a lost chunk to reabsorb it. Lose every cell and the wave restarts.

### Enemies

| Enemy | What it does |
|---|---|
| Crawler | Walks straight at you and bites off a cell |
| Glutton | Eats your lost chunks and grows |
| Brute | Charges in a straight line and is stunned when it hits a wall |

## How it fits the theme

"Bounce back" shows up three ways:

1. Your bolts have to bounce back off the walls before they do anything.
2. The blob bounces back from damage by gathering his own pieces.
3. The janitor bounces back in life, from the person nobody noticed to the one who saves the ship.

## Run it from source

1. Install [Godot 4](https://godotengine.org/download) (built with 4.7.2).
2. Clone this repository:
   ```
   git clone https://github.com/nirvith/resile.git
   ```
3. Open Godot, choose **Import**, and select the `project.godot` file in the cloned folder.
4. Press **F5** to play.

## Built with

- [Godot Engine 4](https://godotengine.org/) and GDScript

## Team

- **Nirvith**: gameplay programming (blob, bolts, chunks, waves)
- **Agastya**: Art, design, and programming map, comics for storytelling


Made in one weekend, November 14 to 15, 2026, for Haven Austin.
