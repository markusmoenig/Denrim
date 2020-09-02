class Game
{
    constructor()
    {
        this.mat = Texture2D.createFromImage({image: "spritesheet"});
        
        System.compileShader({
            shader: "shadername",
        })
        .then( shader => {
            System.log("test is " + shader.isValid)
        })
        .catch(e=>console.log(e))
        
        this.counter = 0;
        this.rotation = 0;
        
        System.setInterval( () => {
            this.rotation += 1;
            this.counter += 1;
            if (this.counter > 18) this.counter = 0;
        }, 66);
        
        this.objects = [];
        for (var i = 0; i < 150; i +=1)
            this.objects.push({
                x: 50 + (i % 10) * 40,
                y: 50 + (i / 10) * 40,
                width: 40,
                height: 40,
                border: 4,
                round: 5,
                rotation: this.rotation,
                borderColor: Color.create(1,0,0,0.4)
            });
    }
    
    touch(event)
    {
        System.log(event.type)
    }
                              
    resize()
    {
    }
    
    draw()
    {
        let main = Texture2D.main();
        main.clear(Color.create(0,0,0,1));
        
        main.drawDisks([{
            x: 5,
            y: 5,
            radius: 100,
            border: 5,
            borderColor: Color.create(1,0,0,0.5)
        }]);
                
        for (var i = 0; i < 150; i +=1)
            this.objects[i].rotation = this.rotation;
                
        main.drawBoxes(this.objects);
        
        main.drawTextures([{
            x: 0,
            y: 0,
            width: 680,
            height: 472,
            alpha: 0.5,
            subRect: Rect2D.create(680 * this.counter,0,680,472),
            texture: this.mat
        }])
    }
}
