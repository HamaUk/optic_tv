package com.kobani4k.app.tv.ui.theme


import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.*
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.*
import androidx.compose.ui.unit.*
import androidx.tv.material3.*



// =================================================
// KOBANI 4K
// FLAT BLUE IPTV TV DESIGN SYSTEM
// =================================================



object UltraTokens {


    // -----------------------------
    // Brand
    // -----------------------------


    val Blue =
        Color(0xFF00A8FF)


    val BlueDark =
        Color(0xFF005BBB)


    val BlueGradient =
        Brush.horizontalGradient(
            listOf(
                Blue,
                BlueDark
            )
        )



    // -----------------------------
    // Background
    // -----------------------------


    val Background =
        Color(0xFF05070C)


    val Surface =
        Color(0xFF10151F)


    val SurfaceHover =
        Color(0xFF172235)


    val SurfaceSelected =
        Color(0xFF1D293B)



    // -----------------------------
    // IPTV Colors
    // -----------------------------


    val Live =
        Color(0xFFE53935)


    val Movie =
        Color(0xFFFFB300)


    val Sports =
        Color(0xFF00C853)


    val UHD =
        Color(0xFFFF6D00)



    // -----------------------------
    // Text
    // -----------------------------


    val Text =
        Color(0xFFF4F7FB)


    val TextSecondary =
        Color(0xFF9AA6B8)


    val Divider =
        Color(0x22FFFFFF)



    // -----------------------------
    // Focus
    // -----------------------------


    val Focus =
        Color(0xFF00A8FF)



    // -----------------------------
    // Radius
    // -----------------------------


    val CardRadius =
        12.dp


    val ButtonRadius =
        10.dp



    // -----------------------------
    // TV Layout
    // -----------------------------


    val SideBar =
        220.dp


    val TopBar =
        80.dp


    val ScreenPadding =
        50.dp

}




// =================================================
// Typography
// =================================================



object UltraFonts {

    val Main =
        FontFamily.SansSerif

}



object UltraType {


    val Hero =
        TextStyle(

            fontFamily = UltraFonts.Main,

            fontSize = 42.sp,

            fontWeight = FontWeight.Bold,

            color = UltraTokens.Text

        )



    val Title =
        TextStyle(

            fontFamily = UltraFonts.Main,

            fontSize = 32.sp,

            fontWeight = FontWeight.Bold,

            color = UltraTokens.Text

        )



    val Section =
        TextStyle(

            fontFamily = UltraFonts.Main,

            fontSize = 24.sp,

            fontWeight = FontWeight.Bold,

            color = UltraTokens.Text

        )



    val Card =
        TextStyle(

            fontFamily = UltraFonts.Main,

            fontSize = 18.sp,

            fontWeight = FontWeight.SemiBold,

            color = UltraTokens.Text

        )



    val Body =
        TextStyle(

            fontFamily = UltraFonts.Main,

            fontSize = 16.sp,

            color = UltraTokens.TextSecondary

        )

}





// =================================================
// TV Focus System
// Flat border only - no glow
// =================================================



@Composable
fun Modifier.kobaniFocus():

        Modifier {


    var focused by remember {

        mutableStateOf(false)

    }


    val scale by animateFloatAsState(

        targetValue =
        if(focused) 1.04f else 1f,


        animationSpec =
        tween(150)

    )



    return this

        .scale(scale)


        .border(

            width =
            if(focused)
                2.dp
            else
                0.dp,


            color =
            if(focused)
                UltraTokens.Focus
            else
                Color.Transparent,


            shape =
            RoundedCornerShape(
                UltraTokens.CardRadius
            )

        )


        .onFocusChanged {

            focused =
                it.isFocused

        }


        .focusable()

}






// =================================================
// Cards
// =================================================



@OptIn(ExperimentalTvMaterial3Api::class)

@Composable

fun kobaniCardColors():

        CardColors {


    return CardDefaults.colors(

        containerColor =
        UltraTokens.Surface,


        contentColor =
        UltraTokens.Text,


        focusedContainerColor =
        UltraTokens.SurfaceSelected,


        focusedContentColor =
        UltraTokens.Text

    )

}





// =================================================
// Buttons
// =================================================



@OptIn(ExperimentalTvMaterial3Api::class)

@Composable

fun kobaniButtonColors():

        ButtonColors {


    return ButtonDefaults.colors(

        containerColor =
        UltraTokens.Surface,


        contentColor =
        UltraTokens.Text,


        focusedContainerColor =
        UltraTokens.Blue,


        focusedContentColor =
        Color.White

    )

}






// =================================================
// IPTV Badge Colors
// =================================================



fun iptvBadgeColor(type:String):Color {


    return when(type.lowercase()) {


        "live" ->
            UltraTokens.Live


        "movie" ->
            UltraTokens.Movie


        "sport" ->
            UltraTokens.Sports


        "4k" ->
            UltraTokens.UHD


        else ->
            UltraTokens.Blue

    }

}
