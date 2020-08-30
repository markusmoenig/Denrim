class Game
{
    constructor()
    {
        this.mat = Texture2D.createFromImage({image: "materials"})
    }
    
    resize()
    {
    }
    
    draw()
    {
        let main = Texture2D.main();
        
        main.clear(Color.create(0,0,0,1));
        
        main.drawDisk({
            x: 0,
            y: 0,
            radius: 100,
            border: 0,
            borderColor: Color.create(1,0,0,1)
        });
        
        main.drawBox({
            x: 200,
            y: 200,
            width: 100,
            height: 100,
            border: 10,
            round: 20,
            borderColor: Color.create(1,1,1,0.2)
        });
        
        main.drawTexture({
            x: 0,
            y: 0,
            width: 200,
            height: 200,
            texture: this.mat
        })
    }
}
